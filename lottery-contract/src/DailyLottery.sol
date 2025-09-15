// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDailyLotteryToken} from "./dailylottery/interface/IDailyLotteryToken.sol";
import {IDailyLotteryNumberLogic} from "./dailylottery/interface/IDailyLotteryNumberLogic.sol";
import {IDailyLotteryRandProvider} from "./dailylottery/interface/IDailyLotteryRand.sol";
import {IDailyLotteryRandCallback} from "./dailylottery/interface/IDailyLotteryRand.sol";

contract DailyLottery is Ownable, IDailyLotteryRandCallback {
    IDailyLotteryToken public nft; // nft
    IDailyLotteryNumberLogic public numberLogic; // number logic
    IDailyLotteryRandProvider public randProvider; // rand provider

    uint64 public lotteryNumber; // current lottery number

    uint256 public pricePerNumber = 0.001 ether; // price per number
    uint8 public feeRate = 5; // fee rate

    bool public isDrawing = false; // VRF is drawing

    struct WinnerData {
        address winner; // the address of the winner
        uint256 tokenId; // the token id of the winner
        uint64 number; // the number of the winner
        uint64 lotteryNumber; // the lottery number
    }

    // winners mapping
    mapping(uint64 lotteryNumber => WinnerData) public winners;

    struct LotteryData {
        uint64 lotteryNumber;
        uint256 pricePerNumber;
        uint8 feeRate;
        uint256 totalAmount;
        uint256 fee;
        uint256 prize;
    }

    // store every lottery data
    mapping(uint64 => LotteryData) public lotterys;
    mapping(uint64 => mapping(address => uint64[])) public userToNumbers; // move it to off-chain later
    mapping(uint64 => mapping(uint64 => address)) public numberToUser;

    error NotEnoughEth(uint256 value);
    error WrongEthValue(uint256 value);
    error DrawingInProgress();
    error NoNumbersToDraw();

    error TransferFailed(uint256 value);

    // event for lottery drawn
    event LotteryDrawn(
        uint64 indexed lotteryNumber,
        uint64 indexed winningNumber,
        address indexed winner,
        uint256 fee,
        uint256 prize
    );

    constructor(
        address _nftAddress,
        address _numberLogicAddress,
        address _randProviderAddress
    ) Ownable(msg.sender) {
        nft = IDailyLotteryToken(_nftAddress);
        numberLogic = IDailyLotteryNumberLogic(_numberLogicAddress);
        randProvider = IDailyLotteryRandProvider(_randProviderAddress);

        // initialize lottery data
        initLotteryData();
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
    function takeNumbers() external payable returns (uint64[] memory) {
        if (isDrawing) {
            revert DrawingInProgress();
        }

        LotteryData storage lotteryData = lotterys[lotteryNumber];
        uint256 _pricePerNumber = lotteryData.pricePerNumber; // get price per number

        // check if the value is correct
        require(msg.value >= _pricePerNumber, NotEnoughEth(msg.value));
        require(msg.value % _pricePerNumber == 0, WrongEthValue(msg.value));

        // generate numbers
        uint64 nums = uint64(msg.value / _pricePerNumber);
        uint64[] memory numbers = numberLogic.takeNumbers(nums);

        // add numbers into lottery data
        uint64[] storage refUserToNumbers = userToNumbers[lotteryNumber][msg.sender];
        for (uint64 i = 0; i < numbers.length; i++) {
            refUserToNumbers.push(numbers[i]);
            numberToUser[lotteryNumber][numbers[i]] = msg.sender;
        }

        // add amount into prize pool
        lotteryData.totalAmount = lotteryData.totalAmount + msg.value;

        return numbers;
    }

    // draw lottery
    function drawLottery() external onlyOwner {
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
        randProvider.requestRandomNumbers(1);
    }

    // error for only rand provider
    error OnlyRandProvider(address sender);

    // VRF callback function
    function callbackFromRand(uint256 _randomNumber) external {
        // check if the sender is the random manager
        require(msg.sender == address(randProvider), OnlyRandProvider(msg.sender));

        // calculate winning number
        uint64 winningNumber = numberLogic.getWinnerNumber(_randomNumber);

        // find winner
        address winner = numberToUser[lotteryNumber][winningNumber];

        // handle fee and prize
        (uint256 fee, uint256 prize) = _handleFeeAndPrize(winner);

        // mint NFT to winner
        uint256 tokenId = nft.safeMint(winner, lotteryNumber);

        // record winning information
        winners[lotteryNumber] = WinnerData({
            winner: winner,
            tokenId: tokenId,
            number: winningNumber,
            lotteryNumber: lotteryNumber
        });

        emit LotteryDrawn(lotteryNumber, winningNumber, winner, fee, prize);

        // reset state, prepare for next lottery
        initLotteryData();

        isDrawing = false;
    }

    function _handleFeeAndPrize(address winner) private returns (uint256 fee, uint256 prize) {
        // caculate prize and fee
        fee = (lotterys[lotteryNumber].totalAmount * feeRate) / 100;
        prize = lotterys[lotteryNumber].totalAmount - fee;

        // transfer fee to owner
        (bool feeSuccess, ) = address(owner()).call{value: fee}("");
        require(feeSuccess, TransferFailed(fee));

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

    // getter functions

    function getAddressByNumber(
        uint64 _lotteryNumber,
        uint64 _number
    ) public view returns (address) {
        return numberToUser[_lotteryNumber][_number];
    }

    function getWinnerData(uint64 _lotteryNumber) public view returns (WinnerData memory) {
        return winners[_lotteryNumber];
    }
}
