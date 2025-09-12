// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DailyLottery} from "src/DailyLottery.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";
import {DailyLotteryNumberLogicV1} from "src/dailylottery/DailyLotteryNumberLogicV1.sol";
import {LotteryVRFProvider} from "src/dailylottery/lotteryVRFProvider.sol";
import {DeployDailyLottery} from "script/DailyLottery.s.sol";

contract DailyLotteryIntegrationTest is Test {
    DailyLottery dailyLottery;
    DailyLotteryNumberLogicV1 dailyLotteryNumberLogicV1;
    DailyLotteryTokenV1 dailyLotteryTokenV1;
    LotteryVRFProvider lotteryVRFProvider;

    function setUp() public {
        // run deploy script
        DeployDailyLottery deployDailyLottery = new DeployDailyLottery();
        // dailyLottery = deployDailyLottery.run();
    }

    function test_TakeNumbers() public {
        // dailyLottery.takeNumbers();
    }

    function test_DrawLottery() public {
        // dailyLottery.drawLottery();
    }
}
