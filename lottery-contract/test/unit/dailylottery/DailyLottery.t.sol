// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DailyLotteryV1} from "src/dailylottery/DailyLotteryV1.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";
import {DailyLotteryNumberLogicV1} from "src/dailylottery/DailyLotteryNumberLogicV1.sol";
import {DailyLotteryVRFProvider} from "src/dailylottery/DailyLotteryVRFProvider.sol";
import {DailyLotteryConfigV1} from "src/dailylottery/DailyLotteryConfigV1.sol";
import {IDailyLotteryToken} from "src/dailylottery/interface/IDailyLotteryToken.sol";
import {IDailyLotteryNumberLogic} from "src/dailylottery/interface/IDailyLotteryNumberLogic.sol";
import {IDailyLotteryRandProvider} from "src/dailylottery/interface/IDailyLotteryRand.sol";
import {IDailyLotteryConfig} from "src/dailylottery/interface/IDailyLotteryConfig.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {LotteryDrawState} from "src/dailylottery/DailyLotteryDef.sol";
import {DailyLotteryVx} from "./mock/DailyLotteryVx.sol";

contract DailyLotteryTest is Test {
    address deployer = makeAddr("deployer");
    DailyLotteryV1 public dailyLottery;
    uint96 baseFee = 0.1 ether; // mock base fee
    uint96 gasPriceLink = 1e9; // mock gas price link
    int256 weiPerUnitLink = 4e15; // 0.004 ether per LINK, aligns with mocks
    VRFCoordinatorV2_5Mock vrfCoordinator;
    IDailyLotteryRandProvider public vrfProviderContract;
    IDailyLotteryToken public tokenContract;
    IDailyLotteryNumberLogic public numberLogicContract;
    IDailyLotteryConfig public configContract;
    uint256 subId;

    function setUp() public {
        vm.startPrank(deployer);

        tokenContract = new DailyLotteryTokenV1();
        numberLogicContract = new DailyLotteryNumberLogicV1();

        vrfCoordinator = new VRFCoordinatorV2_5Mock(baseFee, gasPriceLink, weiPerUnitLink);

        subId = vrfCoordinator.createSubscription();
        vrfProviderContract = new DailyLotteryVRFProvider(
            address(vrfCoordinator),
            subId,
            bytes32(0) // in mock env, keyHash doesn't matter
        );
        vrfCoordinator.addConsumer(subId, address(vrfProviderContract));
        vrfCoordinator.fundSubscription(subId, 100 ether); // mock fund subscription

        // deploy DailyLotteryConfigV1 contract
        configContract = new DailyLotteryConfigV1();

        // deploy DailyLottery implementation contract
        DailyLotteryV1 implementation = new DailyLotteryV1();

        // deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(
            DailyLotteryV1.initialize.selector,
            address(tokenContract),
            address(numberLogicContract),
            address(vrfProviderContract),
            address(configContract)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        dailyLottery = DailyLotteryV1(address(proxy));

        // update the callback asetCallbackAddressyVRFProvider to dailyLottery
        vrfProviderContract.setCallbackAddress(address(dailyLottery));

        // set the allowed minter of DailyLotteryToken to dailyLottery
        tokenContract.setAllowedMinter(address(dailyLottery));

        vm.stopPrank();
    }

    // ================= takeNumbers test case ===================

    function test_TakeNumbers_WrongEthValue() public {
        address account = makeAddr("account");
        vm.deal(account, 0.01 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.0011 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 1)
        );

        assertTrue(!success);
    }

    function test_TakeNumbers_AlreadyDrawing() public {
        address account = makeAddr("account");
        vm.deal(account, 100 ether);

        // take numbers
        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.01 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 10)
        );
        assertTrue(success);

        // draw lottery
        vm.warp(block.timestamp + 1 days); // warp forward 1 day, which is more than minDrawInterval

        // get lottery number
        uint64 lotteryNumber = dailyLottery.lotteryNumber();

        vm.prank(deployer);
        dailyLottery.drawLottery(lotteryNumber);
        LotteryDrawState drawState = dailyLottery.getDrawState(lotteryNumber);
        assertTrue(drawState == LotteryDrawState.Drawing);

        // take numbers again
        vm.prank(account);
        (success, ) = address(dailyLottery).call{value: 0.01 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 10)
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
            abi.encodeWithSignature("takeNumbers(uint64)", 10)
        );
        assertTrue(success);

        uint64 lotteryNumber = dailyLottery.lotteryNumber();
        uint256 pricePerNumber = dailyLottery.getPricePerNumber(lotteryNumber);
        uint256 totalAmount = dailyLottery.getTotalAmount(lotteryNumber);
        assertEq(totalAmount, value);

        uint64[] memory numbers = abi.decode(data, (uint64[]));
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
        emit DailyLotteryV1.TakeNumbersEvent(expectedLotteryNumber, account, new uint64[](0));

        // take numbers
        vm.prank(account);
        (bool success, bytes memory data) = address(dailyLottery).call{value: value}(
            abi.encodeWithSignature("takeNumbers(uint64)", 10)
        );
        assertTrue(success);

        // verify the function returned data
        uint64[] memory numbers = abi.decode(data, (uint64[]));
        assertTrue(numbers.length > 0);
    }

    // =================== drawLottery test case =================

    function test_drawLottery_AlreadyDrawing() public {
        // take numbers
        address account = makeAddr("account");
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 50)
        );
        assertTrue(success);

        // draw lottery
        vm.warp(block.timestamp + 1 days); // warp forward 1 day, which is more than minDrawInterval
        // get lottery number
        uint64 lotteryNumber = dailyLottery.lotteryNumber();

        vm.prank(deployer);
        dailyLottery.drawLottery(lotteryNumber);
        LotteryDrawState drawState = dailyLottery.getDrawState(lotteryNumber);
        assertTrue(drawState == LotteryDrawState.Drawing);

        // draw lottery again
        vm.prank(deployer);
        vm.expectRevert(DailyLotteryV1.DrawingInProgress.selector);
        dailyLottery.drawLottery(lotteryNumber);
    }

    function test_drawLottery_MinDrawIntervalNotMet() public {
        // take numbers for lottery
        address account = makeAddr("account");
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 50)
        );
        assertTrue(success);

        // warp forward but not enough time (less than minDrawInterval)
        // minDrawInterval is 1 days - 1 hour = 82800 seconds
        // let's wait only 1 hour = 3600 seconds, which is much less than 82800
        vm.warp(block.timestamp + 1 hours);
        // get lottery number
        uint64 lotteryNumber = dailyLottery.lotteryNumber();

        // Get lottery data to check drawTime
        uint256 drawTime = dailyLottery.getDrawTime(lotteryNumber);

        // draw lottery - should fail because not enough time has passed
        vm.prank(deployer);
        vm.expectRevert(
            abi.encodeWithSelector(
                DailyLotteryV1.MinDrawIntervalNotMet.selector,
                drawTime,
                block.timestamp
            )
        );
        dailyLottery.drawLottery(lotteryNumber);
    }

    function test_drawLottery_WrongLotteryNumber() public {
        // take numbers for lottery
        address account = makeAddr("account");
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 50)
        );
        assertTrue(success);

        uint64 currentLotteryNumber = dailyLottery.lotteryNumber();
        uint64 wrongLotteryNumber = currentLotteryNumber + 1;

        // warp forward enough time
        vm.warp(block.timestamp + 1 days);

        // draw lottery with wrong lottery number - should fail
        vm.prank(deployer);
        vm.expectRevert(
            abi.encodeWithSelector(
                DailyLotteryV1.WrongLotteryNumber.selector,
                wrongLotteryNumber,
                currentLotteryNumber
            )
        );
        dailyLottery.drawLottery(wrongLotteryNumber);
    }

    function test_draw_lottery() public {
        // mock multiple transactions
        address account = makeAddr("account");
        vm.deal(account, 10 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.05 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 50)
        );
        assertTrue(success);

        address account2 = makeAddr("account2");
        vm.deal(account2, 10 ether);

        vm.prank(account2);
        (success, ) = address(dailyLottery).call{value: 0.005 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 5)
        );
        assertTrue(success);

        // draw lottery
        uint64 oldLotteryNumber = dailyLottery.lotteryNumber();
        vm.warp(block.timestamp + 1 days); // warp forward 1 day, which is more than minDrawInterval

        vm.prank(deployer);
        dailyLottery.drawLottery(oldLotteryNumber);

        LotteryDrawState drawState = dailyLottery.getDrawState(oldLotteryNumber);
        assertTrue(drawState == LotteryDrawState.Drawing);
        assertTrue(dailyLottery.lotteryNumber() == oldLotteryNumber);

        uint256 requestId = DailyLotteryVRFProvider(address(vrfProviderContract)).vrfRequestId();
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
        vrfCoordinator.fulfillRandomWords(requestId, address(vrfProviderContract));

        // check if the lottery is drawn
        LotteryDrawState finalDrawState = dailyLottery.getDrawState(oldLotteryNumber);
        assertTrue(finalDrawState == LotteryDrawState.Drawn);
        assertEq(dailyLottery.lotteryNumber(), oldLotteryNumber + 1);

        DailyLotteryV1.WinnerData memory winnerData = dailyLottery.getWinnerData(oldLotteryNumber);

        assertTrue(winnerData.winner == account || winnerData.winner == account2);
        assertTrue(winnerData.tokenId == 0);
        assertTrue(winnerData.number > 0);
        assertEq(winnerData.lotteryNumber, oldLotteryNumber);
    }

    // =================== Upgradeable Contract Tests =================

    function test_Constructor_DisablesInitialization() public {
        // Deploy implementation contract directly (not through proxy)
        DailyLotteryV1 implementation = new DailyLotteryV1();

        // Try to initialize the implementation contract directly - should fail
        // because constructor calls _disableInitializers()
        vm.expectRevert();
        implementation.initialize(
            address(tokenContract),
            address(numberLogicContract),
            address(vrfProviderContract),
            address(configContract)
        );
    }

    function test_Upgrade_ToDailyLotteryVx() public {
        // Deploy new implementation (DailyLotteryVx)
        DailyLotteryVx newImplementation = new DailyLotteryVx();

        // Store some state before upgrade
        uint64 lotteryNumberBefore = dailyLottery.lotteryNumber();
        address nftContractBefore = address(dailyLottery.nftContract());
        address numberLogicContractBefore = address(dailyLottery.numberLogicContract());

        // Upgrade the contract as owner
        vm.prank(deployer);
        dailyLottery.upgradeToAndCall(address(newImplementation), "");

        // Verify the implementation was upgraded
        // Check that we can call the new function from DailyLotteryVx
        (bool success, bytes memory data) = address(dailyLottery).call(
            abi.encodeWithSignature("version()")
        );
        assertTrue(success);
        string memory version = abi.decode(data, (string));
        assertEq(version, "Vx");

        // Verify state is preserved after upgrade
        assertEq(dailyLottery.lotteryNumber(), lotteryNumberBefore);
        assertEq(address(dailyLottery.nftContract()), nftContractBefore);
        assertEq(address(dailyLottery.numberLogicContract()), numberLogicContractBefore);
    }

    function test_Upgrade_OnlyOwner() public {
        // Deploy new implementation
        DailyLotteryVx newImplementation = new DailyLotteryVx();

        // Non-owner tries to upgrade - should fail
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);
        vm.expectRevert();
        dailyLottery.upgradeToAndCall(address(newImplementation), "");

        // Owner can upgrade
        vm.prank(deployer);
        dailyLottery.upgradeToAndCall(address(newImplementation), "");
    }

    function test_Upgrade_PreservesState() public {
        // Create some state before upgrade
        address account = makeAddr("account");
        vm.deal(account, 100 ether);

        vm.prank(account);
        (bool success, ) = address(dailyLottery).call{value: 0.01 ether}(
            abi.encodeWithSignature("takeNumbers(uint64)", 10)
        );
        assertTrue(success);

        uint64 lotteryNumberBefore = dailyLottery.lotteryNumber();
        uint256 totalAmountBefore = dailyLottery.getTotalAmount(lotteryNumberBefore);

        // Deploy new implementation
        DailyLotteryVx newImplementation = new DailyLotteryVx();

        // Upgrade
        vm.prank(deployer);
        dailyLottery.upgradeToAndCall(address(newImplementation), "");

        // Verify state is preserved
        assertEq(dailyLottery.lotteryNumber(), lotteryNumberBefore);
        assertEq(dailyLottery.getTotalAmount(lotteryNumberBefore), totalAmountBefore);

        // Verify existing functions still work
        assertEq(address(dailyLottery.nftContract()), address(dailyLottery.nftContract()));
    }

    function test_Upgrade_NewFunctionAvailable() public {
        // Deploy new implementation with new function
        DailyLotteryVx newImplementation = new DailyLotteryVx();

        // Before upgrade, version() function should not exist
        (bool successBefore, ) = address(dailyLottery).call(abi.encodeWithSignature("version()"));
        assertFalse(successBefore);

        // Upgrade
        vm.prank(deployer);
        dailyLottery.upgradeToAndCall(address(newImplementation), "");

        // After upgrade, version() function should work
        (bool successAfter, bytes memory data) = address(dailyLottery).call(
            abi.encodeWithSignature("version()")
        );
        assertTrue(successAfter);
        string memory version = abi.decode(data, (string));
        assertEq(version, "Vx");
    }
}
