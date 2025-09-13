// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ScratchCardResultV1} from "src/scratchcard/ScratchCardResultV1.sol";
import {ScratchCardPrize} from "src/scratchcard/ScratchCardDef.sol";

contract ScratchCardResultV1Test is Test {
    ScratchCardResultV1 public result;

    function setUp() public {
        result = new ScratchCardResultV1();
    }

    function test_GrandPrizeprobability() public view {
        // GrandPrize probability is 0.01%, which is 1 in 10,000
        uint256 start = 10001;
        uint256 count = 0;
        uint256 total = 10000;
        for (uint256 i = start; i < start + total; i++) {
            ScratchCardPrize prize = result.getResult(i);
            if (prize == ScratchCardPrize.GrandPrize) {
                count++;
            }
        }
        // Theoretically count should equal total
        assertEq(count, 1, "GrandPrize probability Not Correct");
    }

    function test_SmallPrizeprobability() public view {
        // SmallPrize probability is 1%, which is 1 in 100
        uint256 start = 1001;
        uint256 count = 0;
        uint256 total = 1000;
        for (uint256 i = start; i < start + total; i++) {
            ScratchCardPrize prize = result.getResult(i);
            if (prize == ScratchCardPrize.SmallPrize) {
                count++;
            }
        }
        // Theoretically count should equal total
        assertEq(count, total / 100, "SmallPrize probability Not Correct");
    }

    function test_LuckyPrizeprobability() public view {
        // LuckyPrize probability is 5%, which is 1 in 20
        uint256 start = 1001;
        uint256 count = 0;
        uint256 total = 1000;
        for (uint256 i = start; i < start + total; i++) {
            // Skip numbers divisible by 10000 or 100 (GrandPrize/SmallPrize), only test LuckyPrize
            if (i % 10000 == 0 || i % 100 == 0) continue;
            ScratchCardPrize prize = result.getResult(i);
            if (prize == ScratchCardPrize.LuckyPrize) {
                count++;
            }
        }

        // Theoretically count should equal total / 20 - (total / 100) - (total / 10000)
        assertEq(
            count,
            total / 20 - (total / 100) - (total / 10000),
            "LuckyPrize probability Not Correct"
        );
    }

    function test_NoPrize() public view {
        // Randomly select a number that won't win a prize
        uint256 num = 7;
        ScratchCardPrize prize = result.getResult(num);
        assertEq(uint(prize), uint(ScratchCardPrize.NoPrize), "NoPrize Not Correct");
    }

    function test_Priority_GrandPrizeFirst() public view {
        // When GrandPrize, SmallPrize, LuckyPrize can all divide evenly, should return GrandPrize
        uint256 num = 10000 * 3 * 100 * 20; // Must be divisible by 10000
        ScratchCardPrize prize = result.getResult(num);
        assertEq(uint(prize), uint(ScratchCardPrize.GrandPrize), "GrandPrize priority error");
    }

    function test_Priority_SmallPrizeBeforeLuckyPrize() public view {
        // When both SmallPrize and LuckyPrize can divide evenly, should return SmallPrize
        uint256 num = 100 * 20 * 7; // Can be divided by 100 but not by 10000
        ScratchCardPrize prize = result.getResult(num);
        assertEq(uint(prize), uint(ScratchCardPrize.SmallPrize), "SmallPrize priority error");
    }
}
