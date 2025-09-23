// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {DailyLottery} from "src/DailyLottery.sol";
import {DailyLotteryVRFProvider} from "src/dailylottery/DailyLotteryVRFProvider.sol";
import {IDailyLotteryToken} from "src/dailylottery/interface/IDailyLotteryToken.sol";

contract DeployDailyLottery is Script {
    address public tokenAddress = 0x6142C086C6fCc2e2362D1496D312012914e85f2e;
    address public numberLogicAddress = 0x87eec089a7DF1E676370e797c0d30fD4024d95Ca;
    address public randProviderAddress = 0x5d78e399fD64F57a147e3B17aF9A8bE4e26032B1;

    function run() public {
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy DailyLottery contract
        DailyLottery dailyLottery = new DailyLottery(
            tokenAddress,
            numberLogicAddress,
            randProviderAddress
        );
        address dailyLotteryAddress = address(dailyLottery);

        // set callback address
        DailyLotteryVRFProvider randProvider = DailyLotteryVRFProvider(randProviderAddress);
        randProvider.setCallbackAddress(dailyLotteryAddress);

        // set allowed minter
        IDailyLotteryToken dailyLotteryToken = IDailyLotteryToken(tokenAddress);
        dailyLotteryToken.setAllowedMinter(dailyLotteryAddress);

        // stop broadcast
        vm.stopBroadcast();
    }
}
