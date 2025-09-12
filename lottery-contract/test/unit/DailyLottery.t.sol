// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DailyLottery} from "src/DailyLottery.sol";
import {DailyLotteryTokenV1} from "src/token/DailyLotteryTokenV1.sol";
import {DailyLotteryNumberLogicV1} from "src/DailyLotteryNumberLogicV1.sol";
import {DailyLotteryVRFProvider} from "src/rand/DailylotteryVRFProvider.sol";

contract DailyLotteryTest is Test {
    address deployer = vm.addr(1);
    DailyLottery public dailyLottery;
    uint96 baseFee = 0.1 ether; // mock base fee
    uint96 gasPriceLink = 1e9; // mock gas price link
    int256 weiPerUnitLink = 4e15; // 0.004 ether per LINK, aligns with mocks
    VRFCoordinatorV2_5Mock vrfCoordinator;
    DailyLotteryVRFProvider dailyLotteryVRFProvider;
    uint256 subId;

    function setUp() public {
        vm.startPrank(deployer);

        DailyLotteryTokenV1 dailyLotteryToken = new DailyLotteryTokenV1();
        DailyLotteryNumberLogicV1 dailyLotteryNumberLogic = new DailyLotteryNumberLogicV1();

        vrfCoordinator = new VRFCoordinatorV2_5Mock(baseFee, gasPriceLink, weiPerUnitLink);

        subId = vrfCoordinator.createSubscription();
        dailyLotteryVRFProvider = new DailyLotteryVRFProvider(
            address(vrfCoordinator),
            subId,
            bytes32(0) // in mock env, keyHash doesn't matter
        );
        vrfCoordinator.addConsumer(subId, address(dailyLotteryVRFProvider));
        vrfCoordinator.fundSubscription(subId, 100 ether); // mock fund subscription

        dailyLottery = new DailyLottery(
            address(dailyLotteryToken),
            address(dailyLotteryNumberLogic),
            address(dailyLotteryVRFProvider)
        );

        // update the callback asetCallbackAddressyVRFProvider to dailyLottery
        dailyLotteryVRFProvider.setCallbackAddress(address(dailyLottery));

        // set the allowed minter of DailyLotteryToken to dailyLottery
        dailyLotteryToken.setAllowedMinter(address(dailyLottery));

        vm.stopPrank();
    }

    function test_TakeNumbers_NotEnoughEth() public {
        address account = vm.addr(1);
        vm.deal(account, 0.0009 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.0009 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );

        assertTrue(!success);
    }

    function test_TakeNumbers_WrongEthValue() public {
        address account = vm.addr(1);
        vm.deal(account, 0.01 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.0011 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );

        assertTrue(!success);
    }

    function test_TakeNumbers_AlreadyDrawing() public {
        address account = vm.addr(1);
        vm.deal(account, 100 ether);

        // take numbers
        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.01 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // draw lottery
        vm.prank(dailyLottery.owner());
        dailyLottery.drawLottery();
        assertTrue(dailyLottery.isDrawing());

        // take numbers again
        vm.prank(account);
        (success, ) = address(dailyLottery).call{value: 0.01 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(!success);
    }

    function test_TakeNumbers() public {
        address account = vm.addr(1);
        vm.deal(account, 100 ether);

        // take numbers
        vm.prank(account);
        uint256 value = 0.01 ether;
        (bool success, bytes memory data) = address(dailyLottery).call{value: value}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        uint64 lotteryNumber = dailyLottery.lotteryNumber();
        (, uint256 pricePerNumber, , uint256 totalAmount, , ) = dailyLottery.lotterys(
            lotteryNumber
        );
        assertEq(totalAmount, value);

        (uint64[] memory numbers) = abi.decode(data, (uint64[]));
        assertEq(numbers.length, value / pricePerNumber);
        assertEq(dailyLottery.getAddressByNumber(lotteryNumber, numbers[0]), account);
    }

    function test_drawLottery_AlreadyDrawing() public {
        // take numbers
        address account = vm.addr(1);
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // draw lottery
        vm.prank(dailyLottery.owner());
        dailyLottery.drawLottery();
        assertTrue(dailyLottery.isDrawing());

        // draw lottery again
        vm.prank(dailyLottery.owner());
        vm.expectRevert(DailyLottery.DrawingInProgress.selector);
        dailyLottery.drawLottery();
    }

    function test_draw_lottery() public {
        // mock multiple transactions
        address account = vm.addr(1);
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        address account2 = vm.addr(2);
        vm.deal(account2, 10 ether);

        vm.prank(account2);
        (success, ) = address(dailyLottery).call{value: 0.005 ether}(
            abi.encodeWithSignature("takeNumbers()")
        );
        assertTrue(success);

        // draw lottery
        uint64 oldLotteryNumber = dailyLottery.lotteryNumber();
        vm.startPrank(dailyLottery.owner());
        dailyLottery.drawLottery();
        vm.stopPrank();

        assertTrue(dailyLottery.isDrawing());
        assertTrue(dailyLottery.lotteryNumber() == oldLotteryNumber);

        uint256 requestId = dailyLotteryVRFProvider.vrfRequestId();
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
        vrfCoordinator.fulfillRandomWords(requestId, address(dailyLotteryVRFProvider));

        // check if the lottery is drawn
        assertTrue(!dailyLottery.isDrawing());
        assertEq(dailyLottery.lotteryNumber(), oldLotteryNumber + 1);

        DailyLottery.WinnerData memory winnerData = dailyLottery.getWinnerData(oldLotteryNumber);

        assertTrue(winnerData.winner == account || winnerData.winner == account2);
        assertTrue(winnerData.tokenId == 0);
        assertTrue(winnerData.number > 0);
        assertEq(winnerData.lotteryNumber, oldLotteryNumber);
    }
}
