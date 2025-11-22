// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_RAND_PROVIDER_ADDR} from "./Constants.sol";
import {BaseScratchCardDeploy} from "./BaseScratchCardDeploy.s.sol";
import {ScratchCardVRFProvider} from "src/scratchcard/ScratchCardVRFProvider.sol";

contract DeployScratchCardVRFProvider is BaseScratchCardDeploy {
    function run() public returns (address vrfProviderAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");
        address vrfCoordinator = vm.envAddress("CHAINLINK_VRF_COORDINATOR");
        uint256 subId = vm.envUint("CHAINLINK_VRF_SUBID");
        bytes32 keyHash = vm.envBytes32("CHAINLINK_VRF_KEYHASH");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy ScratchCardVRFProvider contract
        ScratchCardVRFProvider scratchCardVRFProvider = new ScratchCardVRFProvider(
            vrfCoordinator,
            subId,
            keyHash
        );
        vrfProviderAddress = address(scratchCardVRFProvider);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_RAND_PROVIDER_ADDR, vrfProviderAddress);

        return vrfProviderAddress;
    }
}
