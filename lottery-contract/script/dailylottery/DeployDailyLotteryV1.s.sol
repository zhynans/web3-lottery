// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_IMPL_V1_ADDR} from "./Constants.sol";
import {BaseDailyLotteryDeploy} from "./BaseDailyLotteryDeploy.s.sol";
import {DailyLotteryV1} from "src/dailylottery/DailyLotteryV1.sol";

contract DeployDailyLotteryV1 is BaseDailyLotteryDeploy {
    function run() public returns (address implementationAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy DailyLottery implementation contract
        DailyLotteryV1 implementation = new DailyLotteryV1();
        implementationAddress = address(implementation);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_IMPL_V1_ADDR, implementationAddress);

        return implementationAddress;
    }
}
