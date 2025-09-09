// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IDailyLotteryToken {
    function safeMint(address to, uint64 lotteryNumber) external returns (uint256);
}