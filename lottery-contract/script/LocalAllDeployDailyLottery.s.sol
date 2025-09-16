// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {DailyLotteryNumberLogicV1} from "src/dailylottery/DailyLotteryNumberLogicV1.sol";
import {IDailyLotteryToken} from "src/dailylottery/interface/IDailyLotteryToken.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";
import {DailyLotteryVRFProvider} from "src/dailylottery/DailyLotteryVRFProvider.sol";
import {DailyLottery} from "src/DailyLottery.sol";
import {VRFCoordinatorV2_5Mock} from "script/mock/VRFCoordinatorV2_5Mock.sol";

contract LocalAllDeployDailyLottery is Script {
    uint96 public constant BASE_FEE = 0.1 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;
    bytes32 public constant KEY_HASH =
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    function run() public returns (DailyLottery dailyLottery) {
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // roll to a block number
        vm.roll(100); // issue: https://github.com/Cyfrin/foundry-full-course-cu/discussions/2246

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy DailyLotteryNumberLogicV1 contract
        DailyLotteryNumberLogicV1 dailyLotteryNumberLogicV1 = new DailyLotteryNumberLogicV1();

        // deploy DailyLotteryTokenV1 contract
        IDailyLotteryToken dailyLotteryToken = new DailyLotteryTokenV1();

        // Deploy VRF coordinator mock

        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE_LINK,
            WEI_PER_UNIT_LINK
        );
        // Create subscription
        uint256 subId = vrfCoordinator.createSubscription();

        // deploy DailyLotteryVRFProvider contract
        DailyLotteryVRFProvider dailyLotteryVRFProvider = new DailyLotteryVRFProvider(
            address(vrfCoordinator),
            subId,
            KEY_HASH
        );

        // Add consumer to subscription
        vrfCoordinator.addConsumer(subId, address(dailyLotteryVRFProvider));

        // Fund subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);

        // deploy DailyLottery contract
        dailyLottery = new DailyLottery(
            address(dailyLotteryToken),
            address(dailyLotteryNumberLogicV1),
            address(dailyLotteryVRFProvider)
        );

        // set callback address
        dailyLotteryVRFProvider.setCallbackAddress(address(dailyLottery));

        // set allowed minter
        dailyLotteryToken.setAllowedMinter(address(dailyLottery));

        // stop broadcast
        vm.stopBroadcast();

        return dailyLottery;
    }
}
