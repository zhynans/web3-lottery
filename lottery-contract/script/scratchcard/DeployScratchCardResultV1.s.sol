// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_RESULT_ADDR} from "./Constants.sol";
import {BaseScratchCardDeploy} from "./BaseScratchCardDeploy.s.sol";
import {IScratchCardResult} from "src/scratchcard/interface/IScratchCardResult.sol";
import {ScratchCardResultV1} from "src/scratchcard/ScratchCardResultV1.sol";

contract DeployScratchCardResultV1 is BaseScratchCardDeploy {
    function run() public returns (address resultAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy ScratchCardResultV1 contract
        IScratchCardResult scratchCardResult = new ScratchCardResultV1();
        resultAddress = address(scratchCardResult);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_RESULT_ADDR, resultAddress);

        return resultAddress;
    }
}
