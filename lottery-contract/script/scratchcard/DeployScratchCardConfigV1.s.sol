// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_CONFIG_ADDR} from "./Constants.sol";
import {BaseScratchCardDeploy} from "./BaseScratchCardDeploy.s.sol";
import {ScratchCardConfigV1} from "src/scratchcard/ScratchCardConfigV1.sol";

contract DeployScratchCardConfigV1 is BaseScratchCardDeploy {
    function run() public returns (address configAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy ScratchCardConfigV1 contract
        ScratchCardConfigV1 scratchCardConfig = new ScratchCardConfigV1();
        configAddress = address(scratchCardConfig);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_CONFIG_ADDR, configAddress);

        return configAddress;
    }
}
