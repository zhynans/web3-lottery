// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IDailyLotteryRandCallback {
    function callbackFromRand(uint256 _randomNumber) external;
}
