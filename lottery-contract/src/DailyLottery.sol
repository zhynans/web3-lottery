// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDailyLotteryToken} from "./IDailyLotteryToken.sol";
import {IDailyLotteryNumberLogic} from './IDailyLotteryNumberLogic.sol';
import {IDailyLotteryRandomManager} from './random/IDailyLotteryRandomManager.sol';


contract DailyLottery is Ownable{

    IDailyLotteryToken public nft; // nft
    IDailyLotteryNumberLogic public numberLogic; // number logic
    IDailyLotteryRandomManager public randomManager; // random manager

    uint64 public lotteryNumber; // current lottery number

    
    uint256 public pricePerNumber = 0.001 ether; // price per number
    uint8 public feeRate = 5; // fee rate

    
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

        mapping(address => uint64[]) userToNumbers; // move it to off-chain later
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
    
    error TransferFailed(uint256 value);
    error OnlyRandomManager(address sender);

    // event for lottery drawn
    event LotteryDrawn(uint64 lotteryNumber, uint64 winningNumber, address winner, uint256 fee, uint256 prize);

    constructor(
        address _nftAddress,
        address _numberLogicAddress,
        address _randomManagerAddress
    ) Ownable(msg.sender) {
        // initialize lottery data
        initLotteryData();

        nft = IDailyLotteryToken(_nftAddress);
        numberLogic = IDailyLotteryNumberLogic(_numberLogicAddress);
        randomManager = IDailyLotteryRandomManager(_randomManagerAddress);
    }

    function initLotteryData() private {
        lotteryNumber++;

        // since LotteryData structure contains mapping, it cannot be directly assigned using struct literal
        LotteryData storage lotteryData = lotterys[lotteryNumber];
        lotteryData.lotteryNumber = lotteryNumber;
        lotteryData.pricePerNumber = pricePerNumber;
        lotteryData.feeRate = feeRate;
        lotteryData.totalAmount = 0;

        numberLogic.initNumberLogic();
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
        uint64 nums = uint64(msg.value / _pricePerNumber);
        uint64[] memory numbers = numberLogic.takeNumbers(nums);
       
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
        
        // if no one take numbers, skip drawing
        if (!numberLogic.canDraw()) {
            lotteryNumber++;
            emit LotteryDrawn(lotteryNumber, 0, address(0), 0, 0);
            return;
        }

        // set drawing state
        isDrawing = true;
        
        // request a random number
        randomManager.requestRandomNumbers(1);
    }

    // VRF callback function
    function callbackFromRandomManager(uint256 _randomNumber) external {
        // check if the sender is the random manager
        require(msg.sender == address(randomManager), OnlyRandomManager(msg.sender));

        // calculate winning number
        uint64 winningNumber = numberLogic.getWinnerNumber(_randomNumber);

        // find winner
        address winner = lotterys[lotteryNumber].numberToUser[winningNumber];

        // handle fee and prize
        (uint256 fee, uint256 prize) = _handleFeeAndPrize(winner);

        // mint NFT to winner
        uint256 tokenId = nft.safeMint(winner, lotteryNumber);

        // record winning information
        winners[lotteryNumber] = WinnerData({
            winner: winner,
            tokenId: tokenId,
            number: winningNumber,
            lotteryNumberr: lotteryNumber
        });

        emit LotteryDrawn(lotteryNumber, winningNumber, winner, fee, prize);

        // reset state, prepare for next lottery
        initLotteryData();

        isDrawing = false;
    }

    function _handleFeeAndPrize(address winner) private returns(uint256 fee, uint256 prize) {
                // caculate prize and fee
         fee = lotterys[lotteryNumber].totalAmount * feeRate / 100;
         prize = lotterys[lotteryNumber].totalAmount - fee;

        // transfer fee to owner
        (bool feeSuccess, ) = address(owner()).call{value: fee}("");
        require(feeSuccess,  TransferFailed(fee));

        // transfer prize to winner
        (bool prizeSuccess, ) = address(winner).call{value: prize}("");
        require(prizeSuccess, TransferFailed(prize));

        // record lottery data
        LotteryData storage lotteryData = lotterys[lotteryNumber];
        lotteryData.fee = fee;
        lotteryData.prize = prize;

        return (fee, prize);
    }

    function updatePricePerNumber(uint256 _pricePerNumber) public onlyOwner {
        pricePerNumber = _pricePerNumber;
    }

    function updateFeeRate(uint8 _feeRate) public onlyOwner {
        feeRate = _feeRate;
    }

    function updateNftAddress(address _nftAddress) public onlyOwner {
        nft = IDailyLotteryToken(_nftAddress);
    }
    
}