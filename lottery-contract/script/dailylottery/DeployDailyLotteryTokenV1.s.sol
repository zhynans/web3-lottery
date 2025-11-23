// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_TOKEN_ADDR} from "./Constants.sol";
import {BaseDailyLotteryDeploy} from "./BaseDailyLotteryDeploy.s.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";

contract DeployDailyLotteryTokenV1 is BaseDailyLotteryDeploy {
    function run() public returns (address tokenAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy DailyLotteryTokenV1 contract
        DailyLotteryTokenV1 dailyLotteryToken = new DailyLotteryTokenV1();
        tokenAddress = address(dailyLotteryToken);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_TOKEN_ADDR, tokenAddress);

        return tokenAddress;
    }
}
