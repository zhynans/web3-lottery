// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


contract DailyLottery is  VRFConsumerBaseV2Plus {

    uint64 public lotteryNumber; // current lottery number

    // current number, start from 1, increment by 1. 
    // it will reset to 1 when the lottery number is changed.
    uint64 public currentNumber; 

    uint256 public pricePerNumber = 0.001 ether; // price per number
    uint8 public feeRate = 5; // fee rate

    // VRF variables
    bytes32 public keyHash; // VRF key hash
    uint64 public subId; // VRF sub id
    uint32 public callbackGasLimit = 100000; // VRF callback gas limit
    uint16 public requestConfirmations = 3; // VRF request confirmations
    uint32 public numWords = 1; // VRF request random words
    uint256 public s_requestId; // VRF request id
    bool public isDrawing = false; // VRF is drawing

    struct WinnerData {
        address winner; // the address of the winner
        uint256 tokenId; // the token id of the winner
        uint64 number;  // the number of the winner
        uint64 lotteryNumberr; // the lottery number
    }

    // winners mapping
    mapping(uint64 lotteryNumber => WinnerData) public winners;

    struct LotteryData {
        uint64 lotteryNumber;
        uint256 pricePerNumber;
        uint8 feeRate;

        mapping(address => uint64[]) userToNumbers;
        mapping(uint64 => address) numberToUser;

        uint256 totalAmount;
        uint256 fee;
        uint256 prize;
    }

    // store every lottery data
    mapping(uint64 => LotteryData) public lotterys;

    error NotEnoughEth(uint256 value);
    error WrongEthValue(uint256 value);
    error DrawingInProgress();
    error NoNumbersToDraw();
    error VRFRequestFailed();
    error TransferFailed(uint256 value);

    // event for lottery drawn
    event LotteryDrawn(uint64 lotteryNumber, uint64 winningNumber, address winner, uint256 fee, uint256 prize);

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subId
    ) VRFConsumerBaseV2Plus(_vrfCoordinator)  {
        // initialize lottery data
        initLotteryData();

        keyHash = _keyHash;
        subId = _subId;
    }

    function initLotteryData() private {
        lotteryNumber++;
        currentNumber = 1;

        // since LotteryData structure contains mapping, it cannot be directly assigned using struct literal
        LotteryData storage lotteryData = lotterys[lotteryNumber];
        lotteryData.lotteryNumber = lotteryNumber;
        lotteryData.pricePerNumber = pricePerNumber;
        lotteryData.feeRate = feeRate;
        lotteryData.totalAmount = 0;
    }

    // take numbers
    function takeNumbers() public payable returns (uint64[] memory) {
        if (isDrawing) {
            revert DrawingInProgress();
        }

        LotteryData storage lotteryData = lotterys[lotteryNumber];
        uint256 _pricePerNumber = lotteryData.pricePerNumber; // get price per number

        // check if the value is correct
        require(msg.value == _pricePerNumber, NotEnoughEth(msg.value));
        require(msg.value % _pricePerNumber == 0, WrongEthValue(msg.value));

        // generate numbers
        uint64[] memory numbers = new uint64[](msg.value / _pricePerNumber);
        for (uint64 i = 0; i < numbers.length; i++) {
            numbers[i] = currentNumber;
            currentNumber++;
        }
       
        // add numbers into lottery data
        uint64[] storage refUserToNumbers = lotteryData.userToNumbers[msg.sender];
        for (uint64 i = 0; i < numbers.length; i++) {
            refUserToNumbers.push(numbers[i]);
        }

        for (uint64 i = 0; i < numbers.length; i++) {
            lotteryData.numberToUser[numbers[i]] = msg.sender;
        }

        // add amount into prize pool
        lotteryData.totalAmount += msg.value;
        
        return numbers;
    }

    // draw lottery
    function drawLottery() public onlyOwner {
        if (isDrawing) {
            revert DrawingInProgress();
        }
        
        // if the current number is 1, no one take numbers.
        if (currentNumber <= 1) {
            lotteryNumber++;
            return;
        }

        // set drawing state
        isDrawing = true;
        
        // request VRF random number
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    // VRF callback function
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        if (_requestId != s_requestId) {
            revert VRFRequestFailed();
        }

        // get random number and calculate winning number
        uint256 randomNumber = _randomWords[0];
        uint64 winningNumber = uint64((randomNumber % (currentNumber - 1)) + 1); // random value in [1, currentNumber-1]

        // find winner
        address winner = lotterys[lotteryNumber].numberToUser[winningNumber];

        // caculate prize and fee
        uint256 fee = lotterys[lotteryNumber].totalAmount * feeRate / 100;
        uint256 prize = lotterys[lotteryNumber].totalAmount - fee;

        // transfer fee to owner
        (bool feeSuccess, ) = address(owner()).call{value: fee}("");
        require(feeSuccess,  TransferFailed(fee));

        // transfer prize to winner
        (bool prizeSuccess, ) = address(winner).call{value: prize}("");
        require(prizeSuccess, TransferFailed(prize));

        // record winning information
        winners[lotteryNumber] = WinnerData({
            winner: winner,
            tokenId: 0, // set to 0, can be added later
            number: winningNumber,
            lotteryNumberr: lotteryNumber
        });

        // record lottery data
        LotteryData storage lotteryData = lotterys[lotteryNumber];
        lotteryData.fee = fee;
        lotteryData.prize = prize;

        emit LotteryDrawn(lotteryNumber, winningNumber, winner, fee, prize);

        // reset state, prepare for next lottery
        initLotteryData();

        isDrawing = false;
    }

    // set VRF parameters (only owner can call)
    function setVRFParameters(
        uint64 _subId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) public onlyOwner {
        if (_subId != 0) {
            subId = _subId;
        }
        if (_keyHash != 0) {
            keyHash = _keyHash;
        }
        if (_callbackGasLimit != 0) {   
            callbackGasLimit = _callbackGasLimit;
        }
        if (_requestConfirmations != 0) {
            requestConfirmations = _requestConfirmations;
        }
    }

    function updatePricePerNumber(uint256 _pricePerNumber) public onlyOwner {
        pricePerNumber = _pricePerNumber;
    }

    function updateFeeRate(uint8 _feeRate) public onlyOwner {
        feeRate = _feeRate;
    }
    
}