// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_RAND_PROVIDER_ADDR} from "./Constants.sol";
import {BaseDailyLotteryDeploy} from "./BaseDailyLotteryDeploy.s.sol";
import {DailyLotteryVRFProvider} from "src/dailylottery/DailyLotteryVRFProvider.sol";
import {VRFCoordinatorV2_5Mock} from "script/mock/VRFCoordinatorV2_5Mock.sol";

contract DeployLocalDailyLotteryVRFProvider is BaseDailyLotteryDeploy {
    uint96 public constant BASE_FEE = 0.1 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;
    bytes32 public constant KEY_HASH =
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    function run() public returns (address vrfProviderAddress) {
        string memory deploymentFile = getDeploymentFilePath();

        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

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
        vrfProviderAddress = address(dailyLotteryVRFProvider);

        // Add consumer to subscription
        vrfCoordinator.addConsumer(subId, vrfProviderAddress);

        // Fund subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_RAND_PROVIDER_ADDR, vrfProviderAddress);

        return vrfProviderAddress;
    }
}
