// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DailyLottery} from "src/DailyLottery.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";
import {DailyLotteryNumberLogicV1} from "src/dailylottery/DailyLotteryNumberLogicV1.sol";
import {LotteryVRFProvider} from "src/dailylottery/lotteryVRFProvider.sol";
import {LotteryDrawState} from "src/dailylottery/DailyLotteryDef.sol";

contract DailyLotteryTest is Test {
    address deployer = makeAddr("deployer");
    DailyLottery public dailyLottery;
    uint96 baseFee = 0.1 ether; // mock base fee
    uint96 gasPriceLink = 1e9; // mock gas price link
    int256 weiPerUnitLink = 4e15; // 0.004 ether per LINK, aligns with mocks
    VRFCoordinatorV2_5Mock vrfCoordinator;
    LotteryVRFProvider lotteryVRFProvider;
    uint256 subId;

    function setUp() public {
        vm.startPrank(deployer);

        DailyLotteryTokenV1 dailyLotteryToken = new DailyLotteryTokenV1();
        DailyLotteryNumberLogicV1 dailyLotteryNumberLogic = new DailyLotteryNumberLogicV1();

        vrfCoordinator = new VRFCoordinatorV2_5Mock(baseFee, gasPriceLink, weiPerUnitLink);

        subId = vrfCoordinator.createSubscription();
        lotteryVRFProvider = new LotteryVRFProvider(
            address(vrfCoordinator),
            subId,
            bytes32(0) // in mock env, keyHash doesn't matter
        );
        vrfCoordinator.addConsumer(subId, address(lotteryVRFProvider));
        vrfCoordinator.fundSubscription(subId, 100 ether); // mock fund subscription

        dailyLottery = new DailyLottery(
            address(dailyLotteryToken),
            address(dailyLotteryNumberLogic),
            address(lotteryVRFProvider)
        );

        // update the callback asetCallbackAddressyVRFProvider to dailyLottery
        lotteryVRFProvider.setCallbackAddress(address(dailyLottery));

        // set the allowed minter of DailyLotteryToken to dailyLottery
        dailyLotteryToken.setAllowedMinter(address(dailyLottery));

        vm.stopPrank();
    }

    function test_TakeNumbers_NotEnoughEth() public {
        address account = makeAddr("account");
        vm.deal(account, 0.0009 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.0009 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );

        assertTrue(!success);
    }

    function test_TakeNumbers_WrongEthValue() public {
        address account = makeAddr("account");
        vm.deal(account, 0.01 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.0011 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );

        assertTrue(!success);
    }

    function test_TakeNumbers_AlreadyDrawing() public {
        address account = makeAddr("account");
        vm.deal(account, 100 ether);

        // take numbers
        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.01 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // draw lottery
        vm.warp(block.timestamp + 1 days); // warp forward 1 day, which is more than minDrawInterval

        vm.prank(dailyLottery.owner());
        dailyLottery.drawLottery();
        LotteryDrawState drawState = dailyLottery.getDrawState(dailyLottery.lotteryNumber());
        assertTrue(drawState == LotteryDrawState.Drawing);

        // take numbers again
        vm.prank(account);
        (success, ) = address(dailyLottery).call{value: 0.01 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(!success);
    }

    function test_TakeNumbers() public {
        address account = makeAddr("account");
        vm.deal(account, 100 ether);

        // take numbers
        vm.prank(account);
        uint256 value = 0.01 ether;
        (bool success, bytes memory data) = address(dailyLottery).call{value: value}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        uint64 lotteryNumber = dailyLottery.lotteryNumber();
        uint256 pricePerNumber = dailyLottery.getPricePerNumber(lotteryNumber);
        uint256 totalAmount = dailyLottery.getTotalAmount(lotteryNumber);
        assertEq(totalAmount, value);

        (uint64[] memory numbers) = abi.decode(data, (uint64[]));
        assertEq(numbers.length, value / pricePerNumber);
        assertEq(dailyLottery.getAddressByNumber(lotteryNumber, numbers[0]), account);
    }

    function test_TakeNumbers_EmitsEvent() public {
        address account = makeAddr("account");
        vm.deal(account, 100 ether);

        uint64 expectedLotteryNumber = dailyLottery.lotteryNumber();
        uint256 value = 0.01 ether;

        // expect the TakeNumbersEvent to be emitted
        // We check the indexed parameters (lotteryNumber and user) exactly
        // and ignore the non-indexed parameter (numbers array)
        vm.expectEmit(true, true, false, false, address(dailyLottery));
        emit DailyLottery.TakeNumbersEvent(expectedLotteryNumber, account, new uint64[](0));

        // take numbers
        vm.prank(account);
        (bool success, bytes memory data) = address(dailyLottery).call{value: value}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // verify the function returned data
        (uint64[] memory numbers) = abi.decode(data, (uint64[]));
        assertTrue(numbers.length > 0);
    }

    function test_drawLottery_AlreadyDrawing() public {
        // take numbers
        address account = makeAddr("account");
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // draw lottery
        vm.warp(block.timestamp + 1 days); // warp forward 1 day, which is more than minDrawInterval

        vm.prank(dailyLottery.owner());
        dailyLottery.drawLottery();
        LotteryDrawState drawState = dailyLottery.getDrawState(dailyLottery.lotteryNumber());
        assertTrue(drawState == LotteryDrawState.Drawing);

        // draw lottery again
        vm.prank(dailyLottery.owner());
        vm.expectRevert(DailyLottery.DrawingInProgress.selector);
        dailyLottery.drawLottery();
    }

    function test_drawLottery_MinDrawIntervalNotMet() public {
        // take numbers for lottery
        address account = makeAddr("account");
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // warp forward but not enough time (less than minDrawInterval)
        // minDrawInterval is 1 days - 5 minutes = 86100 seconds
        // let's wait only 1 hour = 3600 seconds, which is much less than 86100
        vm.warp(block.timestamp + 1 hours);

        // draw lottery - should fail because not enough time has passed
        vm.prank(dailyLottery.owner());
        vm.expectRevert(
            abi.encodeWithSelector(DailyLottery.MinDrawIntervalNotMet.selector, 1, 3601)
        );
        dailyLottery.drawLottery();
    }

    function test_draw_lottery() public {
        // mock multiple transactions
        address account = makeAddr("account");
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        address account2 = makeAddr("account2");
        vm.deal(account2, 10 ether);

        vm.prank(account2);
        (success, ) = address(dailyLottery).call{value: 0.005 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // draw lottery
        uint64 oldLotteryNumber = dailyLottery.lotteryNumber();
        vm.warp(block.timestamp + 1 days); // warp forward 1 day, which is more than minDrawInterval

        vm.prank(dailyLottery.owner());
        dailyLottery.drawLottery();

        LotteryDrawState drawState = dailyLottery.getDrawState(dailyLottery.lotteryNumber());
        assertTrue(drawState == LotteryDrawState.Drawing);
        assertTrue(dailyLottery.lotteryNumber() == oldLotteryNumber);

        uint256 requestId = lotteryVRFProvider.vrfRequestId();
        assertTrue(requestId > 0);

        // generate random number
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
        vrfCoordinator.fulfillRandomWords(requestId, address(lotteryVRFProvider));

        // check if the lottery is drawn
        LotteryDrawState finalDrawState = dailyLottery.getDrawState(oldLotteryNumber);
        assertTrue(finalDrawState == LotteryDrawState.Drawn);
        assertEq(dailyLottery.lotteryNumber(), oldLotteryNumber + 1);

        DailyLottery.WinnerData memory winnerData = dailyLottery.getWinnerData(oldLotteryNumber);

        assertTrue(winnerData.winner == account || winnerData.winner == account2);
        assertTrue(winnerData.tokenId == 0);
        assertTrue(winnerData.number > 0);
        assertEq(winnerData.lotteryNumber, oldLotteryNumber);
    }
}
