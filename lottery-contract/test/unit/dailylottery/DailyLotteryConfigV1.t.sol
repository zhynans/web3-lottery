// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DailyLotteryConfigV1} from "src/dailylottery/DailyLotteryConfigV1.sol";

contract DailyLotteryConfigV1Test is Test {
    DailyLotteryConfigV1 public config;

    function setUp() public {
        config = new DailyLotteryConfigV1();
    }

    function test_PricePerNumber() public view {
        uint256 expectedPrice = 0.001 ether;
        uint256 actualPrice = config.PricePerNumber();
        assertEq(actualPrice, expectedPrice, "PricePerNumber should return 0.001 ether");
    }

    function test_FeeRate() public view {
        uint8 expectedFeeRate = 5;
        uint8 actualFeeRate = config.FeeRate();
        assertEq(actualFeeRate, expectedFeeRate, "FeeRate should return 5");
    }

    function test_PricePerNumberIsConstant() public view {
        // Test that the price is constant across multiple calls
        uint256 price1 = config.PricePerNumber();
        uint256 price2 = config.PricePerNumber();
        assertEq(price1, price2, "PricePerNumber should be constant");
    }

    function test_FeeRateIsConstant() public view {
        // Test that the fee rate is constant across multiple calls
        uint8 feeRate1 = config.FeeRate();
        uint8 feeRate2 = config.FeeRate();
        assertEq(feeRate1, feeRate2, "FeeRate should be constant");
    }
}
