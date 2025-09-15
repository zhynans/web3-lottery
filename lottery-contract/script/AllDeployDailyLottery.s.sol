// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {DailyLotteryNumberLogicV1} from "src/dailylottery/DailyLotteryNumberLogicV1.sol";
import {IDailyLotteryToken} from "src/dailylottery/interface/IDailyLotteryToken.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";
import {DailyLotteryVRFProvider} from "src/dailylottery/DailyLotteryVRFProvider.sol";
import {DailyLottery} from "src/DailyLottery.sol";

contract AllDeployDailyLottery is Script {
    function run() public returns (DailyLottery dailyLottery) {
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");
        address vrfCoordinator = vm.envAddress("CHAINLINK_VRF_COORDINATOR");
        uint256 subId = vm.envUint("CHAINLINK_VRF_SUBID");
        bytes32 keyHash = vm.envBytes32("CHAINLINK_VRF_KEYHASH");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy DailyLotteryNumberLogicV1 contract
        DailyLotteryNumberLogicV1 dailyLotteryNumberLogicV1 = new DailyLotteryNumberLogicV1();

        // deploy DailyLotteryTokenV1 contract
        IDailyLotteryToken dailyLotteryToken = new DailyLotteryTokenV1();

        // deploy DailyLotteryVRFProvider contract
        DailyLotteryVRFProvider dailyLotteryVRFProvider = new DailyLotteryVRFProvider(
            vrfCoordinator,
            subId,
            keyHash
        );

        // deploy DailyLottery contract
        dailyLottery = new DailyLottery(
            address(dailyLotteryToken),
            address(dailyLotteryNumberLogicV1),
            address(dailyLotteryVRFProvider)
        );

        // set callback address
        dailyLotteryVRFProvider.setCallbackAddress(address(dailyLottery));

        // set allowed minter
        dailyLotteryToken.setAllowedMinter(address(dailyLottery));

        // stop broadcast
        vm.stopBroadcast();

        return dailyLottery;
    }
}
