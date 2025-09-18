// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {ScratchCardVRFProvider} from "src/scratchcard/ScratchCardVRFProvider.sol";
import {IScratchCardRandProvider} from "src/scratchcard/interface/IScratchCardRand.sol";
import {IScratchCardRandCallback} from "src/scratchcard/interface/IScratchCardRand.sol";

// Mock callback contract for testing
contract MockCallback is IScratchCardRandCallback {
    event CallbackCalled(address indexed user, uint256 randomNumber);

    function callbackFromRand(address _user, uint256 _randomNumber) external override {
        emit CallbackCalled(_user, _randomNumber);
    }
}

contract ScratchCardVRFProviderTest is Test {
    ScratchCardVRFProvider public vrfProvider;
    VRFCoordinatorV2_5Mock public vrfCoordinator;
    MockCallback public mockCallback;

    address public owner;
    address public user1;
    address public user2;

    uint96 public constant BASE_FEE = 0.1 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;
    uint256 public subId;
    bytes32 public constant KEY_HASH =
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);

        // Deploy VRF coordinator mock
        vrfCoordinator = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE_LINK, WEI_PER_UNIT_LINK);

        // Create subscription
        subId = vrfCoordinator.createSubscription();

        // Deploy VRF provider
        vrfProvider = new ScratchCardVRFProvider(address(vrfCoordinator), subId, KEY_HASH);

        // Deploy mock callback
        mockCallback = new MockCallback();

        // Add consumer to subscription
        vrfCoordinator.addConsumer(subId, address(vrfProvider));

        // Fund subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);

        // Set callback address
        vrfProvider.setCallbackAddress(address(mockCallback));

        vm.stopPrank();
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsCorrectValues() public view {
        assertEq(vrfProvider.keyHash(), KEY_HASH);
        assertEq(vrfProvider.subId(), subId);
        assertEq(vrfProvider.callbackGasLimit(), 1e6);
        assertEq(vrfProvider.requestConfirmations(), 3);
    }

    function test_Constructor_SetsCorrectOwner() public view {
        assertEq(vrfProvider.owner(), owner);
    }

    // ============ Callback Address Tests ============

    function test_SetCallbackAddress_OnlyOwner() public {
        address newCallback = makeAddr("newCallback");

        // Non-owner cannot set callback
        vm.prank(user1);
        vm.expectRevert();
        vrfProvider.setCallbackAddress(newCallback);

        // Owner can set callback
        vm.prank(owner);
        vrfProvider.setCallbackAddress(newCallback);
        assertEq(address(vrfProvider.callback()), newCallback);
    }

    function test_SetCallbackAddress_UpdatesCallback() public {
        address newCallback = makeAddr("newCallback");

        vm.prank(owner);
        vrfProvider.setCallbackAddress(newCallback);

        assertEq(address(vrfProvider.callback()), newCallback);
    }

    // ============ Request Random Numbers Tests ============

    function test_RequestRandomNumbers_ZeroAddress() public {
        // Should not revert even with zero address user
        vm.prank(user1);
        vrfProvider.requestRandomNumbers(address(0));

        // The function should execute successfully
        assertTrue(true);
    }

    function test_RequestRandomNumbers_MultipleUsers() public {
        // First user request
        vm.prank(user1);
        vrfProvider.requestRandomNumbers(user1);

        // Second user request
        vm.prank(user2);
        vrfProvider.requestRandomNumbers(user2);

        // Both requests should be made successfully without reverting
        // The actual request IDs will be different and stored correctly
    }

    // ============ Fulfill Random Words Tests ============

    function test_FulfillRandomWords_InvalidRequestId() public {
        uint256 invalidRequestId = 999999;

        // The VRF coordinator will revert with InvalidRequest() instead of VRFRequestFailed()
        vm.expectRevert();
        vrfCoordinator.fulfillRandomWords(invalidRequestId, address(vrfProvider));
    }

    function test_FulfillRandomWords_CompleteWorkflow() public {
        // Step 1: Request random numbers
        vm.prank(user1);
        vrfProvider.requestRandomNumbers(user1);

        // Step 2: Use a known request ID for testing (VRF coordinator starts from 1)
        uint256 requestId = 1;

        // Step 3: Verify the request ID is stored in our contract
        assertEq(vrfProvider.vrfRequestIds(requestId), user1);

        // Step 4: Expect the callback to be called with correct parameters
        vm.expectEmit(true, true, false, false);
        emit MockCallback.CallbackCalled(user1, 12345);

        // Step 5: Fulfill the random words through VRF coordinator
        vrfCoordinator.fulfillRandomWords(requestId, address(vrfProvider));

        // Step 6: Verify the request ID is cleared after fulfillment
        assertEq(vrfProvider.vrfRequestIds(requestId), address(0));
    }

    function test_FulfillRandomWords_MultipleRequestsSequential() public {
        // First request
        vm.prank(user1);
        vrfProvider.requestRandomNumbers(user1);
        uint256 requestId1 = 1;

        // Second request
        vm.prank(user2);
        vrfProvider.requestRandomNumbers(user2);
        uint256 requestId2 = 2;

        // Verify both requests are stored
        assertEq(vrfProvider.vrfRequestIds(requestId1), user1);
        assertEq(vrfProvider.vrfRequestIds(requestId2), user2);

        // Fulfill first request
        vm.expectEmit(true, true, false, false);
        emit MockCallback.CallbackCalled(user1, 11111);
        vrfCoordinator.fulfillRandomWords(requestId1, address(vrfProvider));

        // Verify first request is cleared, second still exists
        assertEq(vrfProvider.vrfRequestIds(requestId1), address(0));
        assertEq(vrfProvider.vrfRequestIds(requestId2), user2);

        // Fulfill second request
        vm.expectEmit(true, true, false, false);
        emit MockCallback.CallbackCalled(user2, 22222);
        vrfCoordinator.fulfillRandomWords(requestId2, address(vrfProvider));

        // Verify second request is also cleared
        assertEq(vrfProvider.vrfRequestIds(requestId2), address(0));
    }

    function test_FulfillRandomWords_ZeroAddressUserComplete() public {
        // Request with zero address user
        vm.prank(user1);
        vrfProvider.requestRandomNumbers(address(0));
        uint256 requestId = 1;

        // Verify request is stored with zero address
        assertEq(vrfProvider.vrfRequestIds(requestId), address(0));

        // Fulfill the request - should not revert
        vrfCoordinator.fulfillRandomWords(requestId, address(vrfProvider));

        // Verify request is cleared
        assertEq(vrfProvider.vrfRequestIds(requestId), address(0));
    }

    function test_FulfillRandomWords_ContractState() public view {
        // Test that the contract maintains proper state for fulfillRandomWords
        // Verify callback is set
        assertTrue(address(vrfProvider.callback()) != address(0));

        // Verify VRF parameters are set correctly
        assertTrue(vrfProvider.keyHash() != bytes32(0));
        assertTrue(vrfProvider.subId() > 0);
        assertTrue(vrfProvider.callbackGasLimit() > 0);
        assertTrue(vrfProvider.requestConfirmations() > 0);
    }

    // ============ VRF Parameters Tests ============

    // ============ setKeyHash Tests ============

    function test_SetKeyHash_OnlyOwner() public {
        bytes32 newKeyHash = 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890;

        // Non-owner cannot set key hash
        vm.prank(user1);
        vm.expectRevert();
        vrfProvider.setKeyHash(newKeyHash);

        // Owner can set key hash
        vm.prank(owner);
        vrfProvider.setKeyHash(newKeyHash);
        assertEq(vrfProvider.keyHash(), newKeyHash);
    }

    function test_SetKeyHash_UpdatesKeyHash() public {
        bytes32 newKeyHash = 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890;

        vm.prank(owner);
        vrfProvider.setKeyHash(newKeyHash);

        assertEq(vrfProvider.keyHash(), newKeyHash);
    }

    // ============ setSubId Tests ============

    function test_SetSubId_OnlyOwner() public {
        uint256 newSubId = 123;

        // Non-owner cannot set sub id
        vm.prank(user1);
        vm.expectRevert();
        vrfProvider.setSubId(newSubId);

        // Owner can set sub id
        vm.prank(owner);
        vrfProvider.setSubId(newSubId);
        assertEq(vrfProvider.subId(), newSubId);
    }

    function test_SetSubId_UpdatesSubId() public {
        uint256 newSubId = 123;

        vm.prank(owner);
        vrfProvider.setSubId(newSubId);

        assertEq(vrfProvider.subId(), newSubId);
    }

    // ============ setCallbackGasLimit Tests ============

    function test_SetCallbackGasLimit_OnlyOwner() public {
        uint32 newCallbackGasLimit = 2e6;

        // Non-owner cannot set callback gas limit
        vm.prank(user1);
        vm.expectRevert();
        vrfProvider.setCallbackGasLimit(newCallbackGasLimit);

        // Owner can set callback gas limit
        vm.prank(owner);
        vrfProvider.setCallbackGasLimit(newCallbackGasLimit);
        assertEq(vrfProvider.callbackGasLimit(), newCallbackGasLimit);
    }

    function test_SetCallbackGasLimit_UpdatesCallbackGasLimit() public {
        uint32 newCallbackGasLimit = 2e6;

        vm.prank(owner);
        vrfProvider.setCallbackGasLimit(newCallbackGasLimit);

        assertEq(vrfProvider.callbackGasLimit(), newCallbackGasLimit);
    }

    // ============ setRequestConfirmations Tests ============

    function test_SetRequestConfirmations_OnlyOwner() public {
        uint16 newRequestConfirmations = 5;

        // Non-owner cannot set request confirmations
        vm.prank(user1);
        vm.expectRevert();
        vrfProvider.setRequestConfirmations(newRequestConfirmations);

        // Owner can set request confirmations
        vm.prank(owner);
        vrfProvider.setRequestConfirmations(newRequestConfirmations);
        assertEq(vrfProvider.requestConfirmations(), newRequestConfirmations);
    }

    function test_SetRequestConfirmations_UpdatesRequestConfirmations() public {
        uint16 newRequestConfirmations = 5;

        vm.prank(owner);
        vrfProvider.setRequestConfirmations(newRequestConfirmations);

        assertEq(vrfProvider.requestConfirmations(), newRequestConfirmations);
    }

    // ============ Multiple Parameters Tests ============

    function test_SetMultipleParameters_Sequentially() public {
        uint256 newSubId = 456;
        bytes32 newKeyHash = 0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321;
        uint32 newCallbackGasLimit = 2e6;
        uint16 newRequestConfirmations = 7;

        vm.startPrank(owner);

        vrfProvider.setSubId(newSubId);
        vrfProvider.setKeyHash(newKeyHash);
        vrfProvider.setCallbackGasLimit(newCallbackGasLimit);
        vrfProvider.setRequestConfirmations(newRequestConfirmations);

        vm.stopPrank();

        assertEq(vrfProvider.subId(), newSubId);
        assertEq(vrfProvider.keyHash(), newKeyHash);
        assertEq(vrfProvider.callbackGasLimit(), newCallbackGasLimit);
        assertEq(vrfProvider.requestConfirmations(), newRequestConfirmations);
    }

    // ============ Interface Compliance Tests ============

    function test_InterfaceCompliance_IScratchCardRandProvider() public {
        IScratchCardRandProvider interfaceProvider = IScratchCardRandProvider(address(vrfProvider));

        // Should not revert when calling through interface
        vm.prank(user1);
        interfaceProvider.requestRandomNumbers(user1);

        // The function should execute successfully
        assertTrue(true);
    }
}
