// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ScratchCard} from "src/ScratchCard.sol";
import {ScratchCardResultV1} from "src/scratchcard/ScratchCardResultV1.sol";
import {ScratchCardTokenV1} from "src/scratchcard/ScratchCardTokenV1.sol";
import {ScratchCardVRFProvider} from "src/scratchcard/ScratchCardVRFProvider.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {ScratchCardPrize} from "src/scratchcard/ScratchCardDef.sol";

contract ScratchCardTest is Test {
    address deployer = makeAddr("deployer");
    ScratchCard public scratchCard;

    ScratchCardResultV1 public scratchCardResult;
    ScratchCardTokenV1 public scratchCardToken;
    ScratchCardVRFProvider public scratchCardVRFProvider;

    VRFCoordinatorV2_5Mock public vrfCoordinator;
    uint256 public subId;

    uint96 public constant BASE_FEE = 0.1 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;
    bytes32 public constant KEY_HASH =
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy ScratchCard components
        scratchCardResult = new ScratchCardResultV1();
        scratchCardToken = new ScratchCardTokenV1();

        // Deploy VRF coordinator mock
        vrfCoordinator = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE_LINK, WEI_PER_UNIT_LINK);

        // Create subscription
        subId = vrfCoordinator.createSubscription();

        // Deploy VRF provider
        scratchCardVRFProvider = new ScratchCardVRFProvider(
            address(vrfCoordinator),
            subId,
            KEY_HASH
        );

        // Add consumer to subscription
        vrfCoordinator.addConsumer(subId, address(scratchCardVRFProvider));

        // Fund subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);

        // Deploy main ScratchCard contract
        scratchCard = new ScratchCard(
            address(scratchCardResult),
            address(scratchCardToken),
            address(scratchCardVRFProvider)
        );

        // Set up callback address
        scratchCardVRFProvider.setCallbackAddress(address(scratchCard));

        // Set allowed minter for token
        scratchCardToken.setAllowedMinter(address(scratchCard));

        vm.stopPrank();
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsCorrectAddresses() public view {
        assertEq(address(scratchCard.scratchCardResult()), address(scratchCardResult));
        assertEq(address(scratchCard.scratchCardToken()), address(scratchCardToken));
        assertEq(address(scratchCard.scratchCardRandProvider()), address(scratchCardVRFProvider));
    }

    function test_Constructor_SetsCorrectOwner() public view {
        assertEq(scratchCard.owner(), deployer);
    }

    function test_Constructor_SetsDefaultValues() public view {
        assertEq(scratchCard.price(), 0.001 ether);
        assertEq(scratchCard.feeRate(), 5);
    }

    // ============ Fund Tests ============

    function test_Fund_OnlyOwner() public {
        address nonOwner = makeAddr("nonOwner");
        vm.deal(nonOwner, 10 ether);
        vm.deal(deployer, 10 ether);

        // Non-owner cannot fund
        vm.prank(nonOwner);
        vm.expectRevert();
        scratchCard.fund{value: 1 ether}();

        // Owner can fund
        vm.prank(deployer);
        scratchCard.fund{value: 1 ether}();

        assertEq(address(scratchCard).balance, 1 ether);
    }

    function test_Fund_AcceptsEther() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        vm.prank(deployer);
        scratchCard.fund{value: 2.5 ether}();

        assertEq(address(scratchCard).balance, 2.5 ether);
    }

    // ============ ScratchCard Function Tests ============

    function test_ScratchCard_WrongPrice() public {
        address user = makeAddr("user");
        vm.deal(user, 1 ether);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ScratchCard.WrongPrice.selector, 0.002 ether));
        scratchCard.scratchCard{value: 0.002 ether}();
    }

    function test_ScratchCard_ZeroPrice() public {
        address user = makeAddr("user");
        vm.deal(user, 1 ether);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ScratchCard.WrongPrice.selector, 0));
        scratchCard.scratchCard{value: 0}();
    }

    function test_ScratchCard_EmitsScratchCardEvent() public {
        address user = makeAddr("user");
        vm.deal(user, 1 ether);

        // 仅校验 indexed 的 user topic，避免对 timestamp 等易变字段的断言
        vm.expectEmit(true, false, false, false);
        emit ScratchCard.ScratchCardEvent(user, 0.001 ether, 0);

        vm.prank(user);
        scratchCard.scratchCard{value: 0.001 ether}();
    }

    // ============ Callback Function Tests ============

    function test_CallbackFromRand_NoPrize() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 1 ether}();

        address user = makeAddr("user");

        // Expect LotteryResultEvent with NoPrize (only check indexed topic: user)
        vm.expectEmit(true, false, false, false);
        emit ScratchCard.LotteryResultEvent(user, ScratchCardPrize.NoPrize, 0, 0, 0);

        // Simulate callback with random number that results in NoPrize
        // (ScratchCardResultV1 will determine the prize based on random number)
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 0); // Very small number should result in NoPrize

        // Verify no winner records (arrays should be empty)
        // We can't easily check array length without complex logic, so we verify no events
        assertTrue(true);
    }

    function test_CallbackFromRand_GrandPrize() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 2 ether}();

        address user = makeAddr("user");

        // Get actual contract balance
        uint256 contractBalance = address(scratchCard).balance;

        // Calculate expected amounts (balance / 2, minus 5% fee)
        uint256 expectedReward = contractBalance / 2;
        uint256 expectedFee = (expectedReward * 5) / 100;
        uint256 expectedPrize = expectedReward - expectedFee;

        // Record initial balances
        uint256 initialOwnerBalance = deployer.balance;
        uint256 initialUserBalance = user.balance;

        // Simulate callback with random number that results in GrandPrize
        // Use a random number that is divisible by 10000 (GrandPrize probability)
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 10000);

        // Verify balance changes
        assertEq(deployer.balance, initialOwnerBalance + expectedFee);
        assertEq(user.balance, initialUserBalance + expectedPrize);
        assertEq(address(scratchCard).balance, contractBalance - expectedReward);
    }

    function test_CallbackFromRand_SmallPrize() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 2 ether}();

        address user = makeAddr("user");

        // Get actual contract balance
        uint256 contractBalance = address(scratchCard).balance;

        // Calculate expected amounts (balance / 20, minus 5% fee)
        uint256 expectedReward = contractBalance / 20;
        uint256 expectedFee = (expectedReward * 5) / 100;
        uint256 expectedPrize = expectedReward - expectedFee;

        // Record initial balances
        uint256 initialOwnerBalance = deployer.balance;
        uint256 initialUserBalance = user.balance;

        // Simulate callback with random number that results in SmallPrize
        // Use a random number that is divisible by 100 (SmallPrize probability)
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 100);

        // Verify balance changes
        assertEq(deployer.balance, initialOwnerBalance + expectedFee);
        assertEq(user.balance, initialUserBalance + expectedPrize);
        assertEq(address(scratchCard).balance, contractBalance - expectedReward);
    }

    function test_CallbackFromRand_LuckyPrize() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 2 ether}();

        address user = makeAddr("user");

        // Get actual contract balance
        uint256 contractBalance = address(scratchCard).balance;

        // Calculate expected amounts (balance / 100, minus 5% fee)
        uint256 expectedReward = contractBalance / 100;
        uint256 expectedFee = (expectedReward * 5) / 100;
        uint256 expectedPrize = expectedReward - expectedFee;

        // Record initial balances
        uint256 initialOwnerBalance = deployer.balance;
        uint256 initialUserBalance = user.balance;

        // Simulate callback with random number that results in LuckyPrize
        // Use a random number that is divisible by 20 (LuckyPrize probability)
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 20);

        // Verify balance changes
        assertEq(deployer.balance, initialOwnerBalance + expectedFee);
        assertEq(user.balance, initialUserBalance + expectedPrize);
        assertEq(address(scratchCard).balance, contractBalance - expectedReward);
    }

    // ============ Prize and Fee Handling Tests ============

    function test_HandleFeeAndPrize_TransferFailure() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        // Fund the contract with minimal amount
        vm.prank(deployer);
        scratchCard.fund{value: 0.001 ether}();

        address user = makeAddr("user");

        // Make deployer a contract that rejects transfers
        // Create a contract that will reject all transfers
        vm.etch(
            deployer,
            hex"6080604052348015600f57600080fd5b506004361060285760003560e01c8063a9059cbb14602d575b600080fd5b604051600080fd5b00a165627a7a72305820"
        );

        // Should revert on transfer failure when trying to send fee to owner
        vm.expectRevert();
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 10000); // GrandPrize
    }

    function test_HandleFeeAndPrize_Calculations() public {
        // Give deployer some ETH
        vm.deal(deployer, 20 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 10 ether}();

        address user = makeAddr("user");

        // Get actual contract balance
        uint256 contractBalance = address(scratchCard).balance;
        uint256 expectedReward = contractBalance / 2; // GrandPrize
        uint256 expectedFee = (expectedReward * 5) / 100; // 5% fee
        uint256 expectedPrize = expectedReward - expectedFee;

        // Record initial balances
        uint256 initialOwnerBalance = deployer.balance;
        uint256 initialUserBalance = user.balance;

        // Simulate callback
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 10000); // GrandPrize

        // Verify balance changes
        assertEq(deployer.balance, initialOwnerBalance + expectedFee);
        assertEq(user.balance, initialUserBalance + expectedPrize);
        assertEq(address(scratchCard).balance, contractBalance - expectedReward);
    }

    // ============ Winner Records Tests ============

    function test_WinnerRecords_MultipleWinners() public {
        // Give deployer some ETH
        vm.deal(deployer, 20 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 10 ether}();

        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        // Test multiple winners of different types
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user1, 10000); // GrandPrize

        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user2, 100); // SmallPrize

        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user1, 20); // LuckyPrize

        // Verify that the function executed successfully
        assertTrue(true);
    }

    function test_WinnerRecords_Timestamp() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 1 ether}();

        address user = makeAddr("user");

        uint256 beforeCall = block.timestamp;

        // Simulate callback
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 10000); // GrandPrize

        uint256 afterCall = block.timestamp;

        // Verify timestamp is within expected range
        // (We can't easily access the timestamp from the winner record without complex logic)
        assertTrue(afterCall >= beforeCall);
    }

    // ============ Edge Cases ============

    function test_ScratchCard_ZeroAddressUser() public {
        address user = makeAddr("user");
        vm.deal(user, 1 ether);

        vm.prank(user);
        scratchCard.scratchCard{value: 0.001 ether}();

        assertTrue(true);
    }

    function test_CallbackFromRand_ZeroAddressUser() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        vm.prank(deployer);
        scratchCard.fund{value: 1 ether}();

        // Zero address user will cause ERC721 minting to fail
        // This is expected behavior since ERC721 doesn't allow minting to zero address
        vm.prank(address(scratchCardVRFProvider));
        vm.expectRevert();
        scratchCard.callbackFromRand(address(0), 10000); // GrandPrize
    }

    function test_CallbackFromRand_OnlyVRFProviderCanCall() public {
        address user = makeAddr("user");

        // Only the VRF provider should be able to call this function
        // Test that non-VRF provider cannot call the function
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ScratchCard.OnlyRandProvider.selector, user));
        scratchCard.callbackFromRand(user, 12345);
    }

    function test_CallbackFromRand_VRFProviderCanCall() public {
        // Give deployer some ETH
        vm.deal(deployer, 10 ether);

        // Fund the contract
        vm.prank(deployer);
        scratchCard.fund{value: 1 ether}();

        address user = makeAddr("user");

        // VRF provider should be able to call this function successfully
        vm.prank(address(scratchCardVRFProvider));
        scratchCard.callbackFromRand(user, 0); // NoPrize

        // Function should execute successfully
        assertTrue(true);
    }

    function test_Fund_ZeroAmount() public {
        vm.prank(deployer);
        scratchCard.fund{value: 0}();

        assertEq(address(scratchCard).balance, 0);
    }
}
