// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_CONFIG_ADDR} from "./Constants.sol";
import {BaseDailyLotteryDeploy} from "./BaseDailyLotteryDeploy.s.sol";
import {DailyLotteryConfigV1} from "src/dailylottery/DailyLotteryConfigV1.sol";

contract DeployDailyLotteryConfigV1 is BaseDailyLotteryDeploy {
    function run() public returns (address configAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy DailyLotteryConfigV1 contract
        DailyLotteryConfigV1 dailyLotteryConfig = new DailyLotteryConfigV1();
        configAddress = address(dailyLotteryConfig);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_CONFIG_ADDR, configAddress);

        return configAddress;
    }
}
