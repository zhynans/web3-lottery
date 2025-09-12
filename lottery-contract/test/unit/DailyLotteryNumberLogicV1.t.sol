// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DailyLotteryNumberLogicV1} from "src/DailyLotteryNumberLogicV1.sol";

contract DailyLotteryNumberLogicV1Test is Test {
    DailyLotteryNumberLogicV1 public dailyLotteryNumberLogic;

    function setUp() public {
        dailyLotteryNumberLogic = new DailyLotteryNumberLogicV1();
    }

    function test_initNumberLogic() public {
        dailyLotteryNumberLogic.initNumberLogic();
        assertEq(dailyLotteryNumberLogic.currentNumber(), 1);
    }

    function test_canDraw() public {
        dailyLotteryNumberLogic.initNumberLogic();
        assertEq(dailyLotteryNumberLogic.canDraw(), false);

        dailyLotteryNumberLogic.takeNumbers(1);
        assertEq(dailyLotteryNumberLogic.canDraw(), true);
    }

    function test_takeNumbers() public {
        dailyLotteryNumberLogic.initNumberLogic();

        uint64[] memory numbers = dailyLotteryNumberLogic.takeNumbers(1);
        assertEq(numbers[0], 1);

        uint64[] memory numbers2 = dailyLotteryNumberLogic.takeNumbers(3);
        assertEq(numbers2[0], 2);
        assertEq(numbers2[1], 3);
        assertEq(numbers2[2], 4);
    }

    function test_getWinnerNumberOnBoundary(uint256 randomNumber) public {
        dailyLotteryNumberLogic.initNumberLogic();

        dailyLotteryNumberLogic.takeNumbers(1);
        uint64 winnerNumber = dailyLotteryNumberLogic.getWinnerNumber(randomNumber);
        assertEq(winnerNumber, 1);

        dailyLotteryNumberLogic.takeNumbers(1);
        winnerNumber = dailyLotteryNumberLogic.getWinnerNumber(randomNumber);
        assertTrue(winnerNumber >= 1 && winnerNumber <= 2);
    }
}
