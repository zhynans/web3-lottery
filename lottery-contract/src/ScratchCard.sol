// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IScratchCardResult} from "./scratchcard/interface/IScratchCardResult.sol";
import {IScratchCardToken} from "./scratchcard/interface/IScratchCardToken.sol";
import {ScratchCardPrize} from "./scratchcard/ScratchCardDef.sol";
import {IScratchCardRandCallback} from "./scratchcard/interface/IScratchCardRand.sol";
import {IScratchCardRandProvider} from "./scratchcard/interface/IScratchCardRand.sol";

contract ScratchCard is IScratchCardRandCallback, Ownable {
    IScratchCardResult public scratchCardResult;
    IScratchCardToken public scratchCardToken;
    IScratchCardRandProvider public scratchCardRandProvider;

    uint256 public price = 0.001 ether; // price of scratch card every time
    uint8 public feeRate = 5; // fee rate

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
    event ScratchCardEvent(address indexed user, uint256 value, uint256 timestamp);
    // event for lottery result
    event LotteryResultEvent(
        address indexed user,
        ScratchCardPrize prize,
        uint256 amount,
        uint256 timestamp,
        uint256 randomNumber
    );

    constructor(
        address _scratchCardResult,
        address _scratchCardToken,
        address _scratchCardRandProvider
    ) Ownable(msg.sender) {
        scratchCardResult = IScratchCardResult(_scratchCardResult);
        scratchCardToken = IScratchCardToken(_scratchCardToken);
        scratchCardRandProvider = IScratchCardRandProvider(_scratchCardRandProvider);
    }

    // fund the contract by owner
    function fund() public payable onlyOwner {}

    error WrongPrice(uint256 value);

    function scratchCard() public payable {
        // check buy amount
        require(msg.value == price, WrongPrice(msg.value));

        // request random numbers
        scratchCardRandProvider.requestRandomNumbers(msg.sender);

        // emit scratch card request
        emit ScratchCardEvent(msg.sender, msg.value, block.timestamp);
    }

    // error for only rand provider
    error OnlyRandProvider(address sender);

    function callbackFromRand(address _user, uint256 _randomNumber) external override {
        // check if the sender is the random manager
        require(msg.sender == address(scratchCardRandProvider), OnlyRandProvider(msg.sender));

        // get lottery result
        ScratchCardPrize prize = scratchCardResult.getResult(_randomNumber);

        // if no prize, return immediately
        if (prize == ScratchCardPrize.NoPrize) {
            emit LotteryResultEvent(_user, prize, 0, block.timestamp, _randomNumber);
            return;
        }

        // mint prize token
        scratchCardToken.safeMint(_user, prize);

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
        emit LotteryResultEvent(_user, prize, prizeAmount, block.timestamp, _randomNumber);
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
        feeAmount = (reward * feeRate) / 100;
        prizeAmount = reward - feeAmount;

        // transfer fee to owner
        (bool feeSuccess, ) = address(owner()).call{value: feeAmount}("");
        require(feeSuccess, TransferFailed(feeAmount));

        // transfer prize to winner
        (bool prizeSuccess, ) = address(winner).call{value: prizeAmount}("");
        require(prizeSuccess, TransferFailed(prizeAmount));

        return (feeAmount, prizeAmount);
    }
}
