// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DailyLotteryVRFProvider} from "src/rand/DailylotteryVRFProvider.sol";
import {DailyLotteryRandCallbackMock} from "./DailyLotteryRandCallbackMock.sol";

contract DailyLotteryVRFProviderTest is Test {
    DailyLotteryVRFProvider public dailyLotteryVRFProvider;
    VRFCoordinatorV2_5Mock public vrfCoordinator;
    DailyLotteryRandCallbackMock public callback;
    uint256 public subId;
    uint96 baseFee = 0.1 ether; // mock base fee
    uint96 gasPriceLink = 1e9; // mock gas price link
    int256 weiPerUnitLink = 4e15; // 0.004 ether per LINK, aligns with mocks

    function setUp() public {
        vrfCoordinator = new VRFCoordinatorV2_5Mock(baseFee, gasPriceLink, weiPerUnitLink);
        subId = vrfCoordinator.createSubscription();
        dailyLotteryVRFProvider = new DailyLotteryVRFProvider(
            address(vrfCoordinator),
            subId,
            bytes32(0) // in mock env, keyHash doesn't matter
        );
        vrfCoordinator.addConsumer(subId, address(dailyLotteryVRFProvider));
        vrfCoordinator.fundSubscription(subId, 100 ether); // mock fund subscription

        callback = new DailyLotteryRandCallbackMock();
        dailyLotteryVRFProvider.setCallbackAddress(address(callback));
    }

    function test_RequestRandomNumberOnAlreadyRequested() public {
        dailyLotteryVRFProvider.requestRandomNumbers(1);
        vm.expectRevert(DailyLotteryVRFProvider.VRFRequestAlreadyRequested.selector);
        dailyLotteryVRFProvider.requestRandomNumbers(1);
    }

    function test_RequestRandomNumber() public {
        dailyLotteryVRFProvider.requestRandomNumbers(1);
        uint256 requestId = dailyLotteryVRFProvider.vrfRequestId();

        // assert VRF coordinator's RandomWordsFulfilled event, only check indexed requestId and subId
        vm.expectEmit(true, true, false, false, address(vrfCoordinator));
        emit VRFCoordinatorV2_5Mock.RandomWordsFulfilled(
            requestId,
            0,
            subId,
            0,
            false,
            false,
            false
        );
        vrfCoordinator.fulfillRandomWords(requestId, address(dailyLotteryVRFProvider));
    }
}
