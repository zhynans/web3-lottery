// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {console} from "forge-std/console.sol";
import {IDailyLotteryRandCallback} from "src/rand/IDailyLotteryRandCallback.sol";

contract DailyLotteryRandCallbackMock is IDailyLotteryRandCallback {
    function callbackFromRand(uint256 _randomNumber) external pure override {
        console.log("RandomNumberReceived", _randomNumber);
    }
}
