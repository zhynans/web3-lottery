// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IDailyLotteryRandProvider {

    function requestRandomNumbers(uint32 nums) external;
}