// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ScratchCardConfigV1} from "src/scratchcard/ScratchCardConfigV1.sol";

contract ScratchCardConfigV1Test is Test {
    ScratchCardConfigV1 public config;

    function setUp() public {
        config = new ScratchCardConfigV1();
    }

    function test_Price() public view {
        uint256 expectedPrice = 0.001 ether;
        uint256 actualPrice = config.Price();
        assertEq(actualPrice, expectedPrice, "Price should return 0.001 ether");
    }

    function test_FeeRate() public view {
        uint8 expectedFeeRate = 5;
        uint8 actualFeeRate = config.FeeRate();
        assertEq(actualFeeRate, expectedFeeRate, "FeeRate should return 5");
    }

    function test_PriceIsConstant() public view {
        // Test that the price is constant across multiple calls
        uint256 price1 = config.Price();
        uint256 price2 = config.Price();
        assertEq(price1, price2, "Price should be constant");
    }

    function test_FeeRateIsConstant() public view {
        // Test that the fee rate is constant across multiple calls
        uint8 feeRate1 = config.FeeRate();
        uint8 feeRate2 = config.FeeRate();
        assertEq(feeRate1, feeRate2, "FeeRate should be constant");
    }
}

