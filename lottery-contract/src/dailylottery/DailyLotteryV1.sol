// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IDailyLotteryToken} from "./interface/IDailyLotteryToken.sol";
import {IDailyLotteryNumberLogic} from "./interface/IDailyLotteryNumberLogic.sol";
import {
    IDailyLotteryRandCallback,
    IDailyLotteryRandProvider
} from "./interface/IDailyLotteryRand.sol";
import {IDailyLotteryConfig} from "./interface/IDailyLotteryConfig.sol";
import {LotteryDrawState} from "./DailyLotteryDef.sol";

contract DailyLotteryV1 is
    IDailyLotteryRandCallback,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    IDailyLotteryToken public nftContract; // nft contract
    IDailyLotteryNumberLogic public numberLogicContract; // number logic contract
    IDailyLotteryRandProvider public randProviderContract; // rand provider contract
    IDailyLotteryConfig public configContract; // config contract

    uint64 public lotteryNumber; // current lottery number

    uint64 public minDrawInterval; // min interval between two lotteries

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
        LotteryDrawState drawState;
        uint256 drawTime;
    }

    // store every lottery data
    mapping(uint64 => LotteryData) public lotterys;
    mapping(uint64 => mapping(uint64 => address)) public numberToUser;

    error WrongEthValue(uint256 value);
    error NoNumbersToDraw();

    error WrongLotteryNumber(uint64 param, uint64 current);
    error DrawingInProgress();
    error MinDrawIntervalNotMet(uint256 startTime, uint256 currentTime);

    error TransferFailed(uint256 value);

    // event for take numbers
    event TakeNumbersEvent(uint64 indexed lotteryNumber, address indexed user, uint64[] numbers);

    // event for lottery drawn
    event LotteryDrawnEvent(
        uint64 indexed lotteryNumber,
        address indexed winner,
        uint64 winnerNumber,
        uint256 fee,
        uint256 prize,
        uint256 drawTime
    );

    // =================== upgradable function =============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 把 initialized 状态设置为 true，防止逻辑合约被攻击者初始化
    }

    function initialize(
        address _nftAddr,
        address _numberLogicAddr,
        address _randProviderAddr,
        address _configAddr
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        nftContract = IDailyLotteryToken(_nftAddr);
        numberLogicContract = IDailyLotteryNumberLogic(_numberLogicAddr);
        randProviderContract = IDailyLotteryRandProvider(_randProviderAddr);
        configContract = IDailyLotteryConfig(_configAddr);
        minDrawInterval = 1 days - 1 hours;

        // initialize lottery data
        initNextLotteryData();
    }

    // UUPS授权函数（必须实现）：不需要执行额外逻辑，真正的安全逻辑由修饰器onlyOwner控制，防止恶意升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ======================= upgradable function end =====================

    // ============ Lottery Data Functions ============

    function initNextLotteryData() private {
        lotteryNumber++;

        // since LotteryData structure contains mapping, it cannot be directly assigned using struct literal
        LotteryData storage lotteryData = lotterys[lotteryNumber];
        lotteryData.lotteryNumber = lotteryNumber;
        lotteryData.pricePerNumber = _pricePerNumber();
        lotteryData.feeRate = _feeRate();
        lotteryData.totalAmount = 0;
        lotteryData.drawState = LotteryDrawState.NotDrawn;
        lotteryData.drawTime = block.timestamp; // it represents the start time of the lottery before drawn

        numberLogicContract.initNumberLogic();
    }

    function drawLotteryData(LotteryData storage lotteryData) private {
        lotteryData.drawState = LotteryDrawState.Drawing;
    }

    function finishLotteryData(LotteryData storage lotteryData) private {
        lotteryData.drawState = LotteryDrawState.Drawn;
        lotteryData.drawTime = block.timestamp;
    }

    // take numbers
    function takeNumbers(uint64 nums) external payable returns (uint64[] memory) {
        LotteryData storage lotteryData = lotterys[lotteryNumber];

        // check draw state
        if (lotteryData.drawState == LotteryDrawState.Drawing) {
            revert DrawingInProgress();
        }

        uint256 _price = lotteryData.pricePerNumber; // get price per number

        // check if the value is correct
        require(msg.value == _price * nums, WrongEthValue(msg.value));

        // generate numbers
        uint64[] memory numbers = numberLogicContract.takeNumbers(nums);

        // add numbers into lottery data
        for (uint64 i = 0; i < numbers.length; i++) {
            numberToUser[lotteryNumber][numbers[i]] = msg.sender;
        }

        // add amount into prize pool
        lotteryData.totalAmount = lotteryData.totalAmount + msg.value;

        // emit event for take numbers
        emit TakeNumbersEvent(lotteryNumber, msg.sender, numbers);

        return numbers;
    }

    // draw lottery
    function drawLottery(uint64 _lotteryNumber) external onlyOwner {
        // check lottery number
        require(_lotteryNumber == lotteryNumber, WrongLotteryNumber(_lotteryNumber, lotteryNumber));

        LotteryData storage lotteryData = lotterys[lotteryNumber];

        // check draw state
        require(lotteryData.drawState == LotteryDrawState.NotDrawn, DrawingInProgress());
        // check draw time
        require(
            block.timestamp - lotteryData.drawTime >= minDrawInterval,
            MinDrawIntervalNotMet(lotteryData.drawTime, block.timestamp)
        );

        // if no one take numbers, skip drawing
        if (!numberLogicContract.canDraw()) {
            finishLotteryData(lotteryData);
            emit LotteryDrawnEvent(lotteryNumber, address(0), 0, 0, 0, block.timestamp);

            initNextLotteryData();
            return;
        }

        // set drawing state
        drawLotteryData(lotteryData);

        // request a random number
        randProviderContract.requestRandomNumbers(1);
    }

    // error for only rand provider
    error OnlyRandProvider(address sender);

    // VRF callback function
    function callbackFromRand(uint256 _randomNumber) external {
        // check if the sender is the random manager
        require(msg.sender == address(randProviderContract), OnlyRandProvider(msg.sender));

        // calculate winning number
        uint64 winnerNumber = numberLogicContract.getWinnerNumber(_randomNumber);

        // find winner
        address winner = numberToUser[lotteryNumber][winnerNumber];

        // handle fee and prize
        (uint256 fee, uint256 prize) = _handleFeeAndPrize(winner);

        // mint NFT to winner
        uint256 tokenId = nftContract.safeMint(winner, lotteryNumber);

        // record winning information
        winners[lotteryNumber] = WinnerData({
            winner: winner,
            tokenId: tokenId,
            number: winnerNumber,
            lotteryNumber: lotteryNumber
        });

        // finish lottery data
        LotteryData storage lotteryData = lotterys[lotteryNumber];
        finishLotteryData(lotteryData);

        emit LotteryDrawnEvent(
            lotteryNumber,
            winner,
            winnerNumber,
            fee,
            prize,
            lotteryData.drawTime
        );

        //  prepare for next lottery data
        initNextLotteryData();
    }

    function _handleFeeAndPrize(address winner) private returns (uint256 fee, uint256 prize) {
        // caculate prize and fee
        uint8 currentFeeRate = _feeRate();
        fee = (lotterys[lotteryNumber].totalAmount * currentFeeRate) / 100;
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

    function updateConfigAddress(address _configAddress) public onlyOwner {
        configContract = IDailyLotteryConfig(_configAddress);
    }

    // ============= config functions ============

    function _pricePerNumber() private view returns (uint256) {
        return configContract.PricePerNumber();
    }

    function _feeRate() private view returns (uint8) {
        return configContract.FeeRate();
    }

    // ============= getter functions =============

    function getAddressByNumber(
        uint64 _lotteryNumber,
        uint64 _number
    ) public view returns (address) {
        return numberToUser[_lotteryNumber][_number];
    }

    function getWinnerData(uint64 _lotteryNumber) public view returns (WinnerData memory) {
        return winners[_lotteryNumber];
    }

    function getTotalAmount(uint64 _lotteryNumber) public view returns (uint256) {
        return lotterys[_lotteryNumber].totalAmount;
    }

    function getDrawState(uint64 _lotteryNumber) public view returns (LotteryDrawState) {
        return lotterys[_lotteryNumber].drawState;
    }

    function getPricePerNumber(uint64 _lotteryNumber) public view returns (uint256) {
        return lotterys[_lotteryNumber].pricePerNumber;
    }

    function getFeeRate(uint64 _lotteryNumber) public view returns (uint8) {
        return lotterys[_lotteryNumber].feeRate;
    }

    function getDrawTime(uint64 _lotteryNumber) public view returns (uint256) {
        return lotterys[_lotteryNumber].drawTime;
    }

    // ============= set function =============

    function setRandProviderAddress(address _randProviderAddress) public onlyOwner {
        randProviderContract = IDailyLotteryRandProvider(_randProviderAddress);
    }

    function setNftAddress(address _nftAddress) public onlyOwner {
        nftContract = IDailyLotteryToken(_nftAddress);
    }

    function setNumberLogicAddress(address _numberLogicAddress) public onlyOwner {
        numberLogicContract = IDailyLotteryNumberLogic(_numberLogicAddress);
    }

    function setMinDrawInterval(uint64 _minDrawInterval) public onlyOwner {
        minDrawInterval = _minDrawInterval;
    }
}
