// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IDailyLotteryConfig} from "./interface/IDailyLotteryConfig.sol";

contract DailyLotteryConfigV1 is IDailyLotteryConfig {
    uint256 private constant PRICE_PERNUMBER = 0.001 ether;
    uint8 private constant FEE_RATE = 5; // 手续费，如果5%，返回5

    // 每个号多少钱
    function PricePerNumber() external pure returns (uint256) {
        return PRICE_PERNUMBER;
    }

    // 手续费
    function FeeRate() external pure returns (uint8) {
        return FEE_RATE;
    }
}
