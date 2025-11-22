// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseDeploy} from "script/BaseDeploy.s.sol";

contract BaseDailyLotteryDeploy is BaseDeploy {
    function getDeploymentFilePath() internal view returns (string memory) {
        return super.getDeploymentFilePath("daily-lottery");
    }
}
