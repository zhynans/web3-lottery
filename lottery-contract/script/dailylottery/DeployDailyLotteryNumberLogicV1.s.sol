// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DEPLOY_NUMBER_LOGIC_ADDR} from "./Constants.sol";
import {BaseDailyLotteryDeploy} from "./BaseDailyLotteryDeploy.s.sol";
import {DailyLotteryNumberLogicV1} from "src/dailylottery/DailyLotteryNumberLogicV1.sol";

contract DeployDailyLotteryNumberLogicV1 is BaseDailyLotteryDeploy {
    function run() public returns (address numberLogicAddress) {
        string memory deploymentFile = getDeploymentFilePath();
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy DailyLotteryNumberLogicV1 contract
        DailyLotteryNumberLogicV1 dailyLotteryNumberLogicV1 = new DailyLotteryNumberLogicV1();
        numberLogicAddress = address(dailyLotteryNumberLogicV1);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_NUMBER_LOGIC_ADDR, numberLogicAddress);

        return numberLogicAddress;
    }
}
