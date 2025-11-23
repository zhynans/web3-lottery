// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DailyLotteryV1} from "src/dailylottery/DailyLotteryV1.sol";
contract DailyLotteryVx is DailyLotteryV1 {
    function version() external pure returns (string memory) {
        return "Vx";
    }
}
