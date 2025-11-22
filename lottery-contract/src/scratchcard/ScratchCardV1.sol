// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IScratchCardConfig} from "./interface/IScratchCardConfig.sol";
import {IScratchCardRandCallback} from "./interface/IScratchCardRand.sol";
import {IScratchCardRandProvider} from "./interface/IScratchCardRand.sol";
import {IScratchCardResult} from "./interface/IScratchCardResult.sol";
import {IScratchCardToken} from "./interface/IScratchCardToken.sol";
import {ScratchCardPrize} from "./ScratchCardDef.sol";

contract ScratchCardV1 is
    IScratchCardRandCallback,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    IScratchCardResult public resultContract;
    IScratchCardToken public tokenContract;
    IScratchCardRandProvider public randProviderContract;
    IScratchCardConfig public configContract;

    struct WinnerData {
        address user;
        ScratchCardPrize prize;
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }

    WinnerData[] public grandWinners;
    WinnerData[] public smallWinners;
    WinnerData[] public luckyWinners;

    // event for scratch card
    event ScratchCardEvent(address indexed user, uint256 indexed timestamp, uint256 value);
    // event for lottery result
    event LotteryResultEvent(
        address indexed user,
        uint256 indexed timestamp,
        ScratchCardPrize indexed prize,
        uint256 amount,
        uint256 randomNumber
    );

    // =================== upgradable function =============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 把 initialized 状态设置为 true，防止逻辑合约被攻击者初始化
    }

    function initialize(
        address _resultAddr,
        address _tokenAddr,
        address _randProviderAddr,
        address _configAddr
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        resultContract = IScratchCardResult(_resultAddr);
        tokenContract = IScratchCardToken(_tokenAddr);
        randProviderContract = IScratchCardRandProvider(_randProviderAddr);
        configContract = IScratchCardConfig(_configAddr);
    }

    // UUPS授权函数（必须实现）：不需要执行额外逻辑，真正的安全逻辑由修饰器onlyOwner控制，防止恶意升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // =================== business function =============

    // fund the contract by owner
    function fund() public payable onlyOwner {}

    error WrongPrice(uint256 value);

    function scratchCard() public payable {
        // check buy amount
        uint256 price = _price();
        require(msg.value == price, WrongPrice(msg.value));

        // request random numbers
        randProviderContract.requestRandomNumbers(msg.sender);

        // emit scratch card request
        emit ScratchCardEvent(msg.sender, block.timestamp, msg.value);
    }

    // error for only rand provider
    error OnlyRandProvider(address sender);

    function callbackFromRand(address _user, uint256 _randomNumber) external override {
        // check if the sender is the random manager
        require(msg.sender == address(randProviderContract), OnlyRandProvider(msg.sender));

        // get lottery result
        ScratchCardPrize prize = resultContract.getResult(_randomNumber);

        // if no prize, return immediately
        if (prize == ScratchCardPrize.NoPrize) {
            emit LotteryResultEvent(_user, block.timestamp, prize, 0, _randomNumber);
            return;
        }

        // mint prize token
        tokenContract.safeMint(_user, prize);

        // handle prize and fee
        (, uint256 prizeAmount) = _handleFeeAndPrize(_user, prize);

        // record winner data
        WinnerData memory winnerData = WinnerData({
            user: _user,
            prize: prize,
            tokenId: 0,
            amount: prizeAmount,
            timestamp: block.timestamp
        });

        if (prize == ScratchCardPrize.GrandPrize) {
            grandWinners.push(winnerData);
        } else if (prize == ScratchCardPrize.SmallPrize) {
            smallWinners.push(winnerData);
        } else if (prize == ScratchCardPrize.LuckyPrize) {
            luckyWinners.push(winnerData);
        }

        // emit lottery result
        emit LotteryResultEvent(_user, block.timestamp, prize, prizeAmount, _randomNumber);
    }

    error TransferFailed(uint256 value);

    function _handleFeeAndPrize(
        address winner,
        ScratchCardPrize prize
    ) private returns (uint256 feeAmount, uint256 prizeAmount) {
        // get balance of the contract
        uint256 balance = address(this).balance;

        // caculate prize and fee
        uint256 reward = 0;
        if (prize == ScratchCardPrize.GrandPrize) {
            reward = balance / 2;
        } else if (prize == ScratchCardPrize.SmallPrize) {
            reward = balance / 20;
        } else if (prize == ScratchCardPrize.LuckyPrize) {
            reward = balance / 100;
        }

        // caculate fee
        uint8 feeRate = _feeRate();
        feeAmount = (reward * uint256(feeRate)) / 100;
        prizeAmount = reward - feeAmount;

        // transfer fee to owner
        (bool feeSuccess, ) = address(owner()).call{value: feeAmount}("");
        require(feeSuccess, TransferFailed(feeAmount));

        // transfer prize to winner
        (bool prizeSuccess, ) = address(winner).call{value: prizeAmount}("");
        require(prizeSuccess, TransferFailed(prizeAmount));

        return (feeAmount, prizeAmount);
    }

    // =========== config function ===========

    function _price() private view returns (uint256) {
        return configContract.Price();
    }

    function _feeRate() private view returns (uint8) {
        return configContract.FeeRate();
    }

    // =========== set function ===========

    function setResultAddress(address _address) public onlyOwner {
        resultContract = IScratchCardResult(_address);
    }

    function setTokenAddress(address _address) public onlyOwner {
        tokenContract = IScratchCardToken(_address);
    }

    function setRandProviderAddress(address _address) public onlyOwner {
        randProviderContract = IScratchCardRandProvider(_address);
    }

    function setConfigAddress(address _address) public onlyOwner {
        configContract = IScratchCardConfig(_address);
    }
}
