// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_IMPL_V1_ADDR} from "./Constants.sol";
import {BaseScratchCardDeploy} from "./BaseScratchCardDeploy.s.sol";
import {ScratchCardV1} from "src/scratchcard/ScratchCardV1.sol";

contract DeployScratchCardV1 is BaseScratchCardDeploy {
    function run() public returns (address implementationAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy ScratchCard implementation contract
        ScratchCardV1 implementation = new ScratchCardV1();
        implementationAddress = address(implementation);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_IMPL_V1_ADDR, implementationAddress);

        return implementationAddress;
    }
}
