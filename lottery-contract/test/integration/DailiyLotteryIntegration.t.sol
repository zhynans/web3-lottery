// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DailyLottery} from "src/DailyLottery.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";
import {DailyLotteryNumberLogicV1} from "src/dailylottery/DailyLotteryNumberLogicV1.sol";
import {DailyLotteryVRFProvider} from "src/dailylottery/DailyLotteryVRFProvider.sol";
import {AllDeployDailyLottery} from "script/AllDeployDailyLottery.s.sol";

contract DailyLotteryIntegrationTest is Test {
    DailyLottery dailyLottery;
    DailyLotteryNumberLogicV1 dailyLotteryNumberLogicV1;
    DailyLotteryTokenV1 dailyLotteryTokenV1;
    DailyLotteryVRFProvider lotteryVRFProvider;

    function setUp() public {
        // run deploy script
        // AllDeployDailyLottery deployDailyLottery = new AllDeployDailyLottery();
        // dailyLottery = deployDailyLottery.run();
    }

    function test_TakeNumbers() public {
        // dailyLottery.takeNumbers();
    }

    function test_DrawLottery() public {
        // dailyLottery.drawLottery();
    }
}
