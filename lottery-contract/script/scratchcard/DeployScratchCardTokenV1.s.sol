// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_TOKEN_ADDR} from "./Constants.sol";
import {BaseScratchCardDeploy} from "./BaseScratchCardDeploy.s.sol";
import {IScratchCardToken} from "src/scratchcard/interface/IScratchCardToken.sol";
import {ScratchCardTokenV1} from "src/scratchcard/ScratchCardTokenV1.sol";

contract DeployScratchCardTokenV1 is BaseScratchCardDeploy {
    function run() public returns (address tokenAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy ScratchCardTokenV1 contract
        IScratchCardToken scratchCardToken = new ScratchCardTokenV1();
        tokenAddress = address(scratchCardToken);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_TOKEN_ADDR, tokenAddress);

        return tokenAddress;
    }
}
