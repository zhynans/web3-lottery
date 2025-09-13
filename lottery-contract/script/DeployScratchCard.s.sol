// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {IScratchCardResult} from "src/scratchcard/interface/IScratchCardResult.sol";
import {IScratchCardToken} from "src/scratchcard/interface/IScratchCardToken.sol";
import {IScratchCardRandProvider} from "src/scratchcard/interface/IScratchCardRand.sol";
import {ScratchCardResultV1} from "src/scratchcard/ScratchCardResultV1.sol";
import {ScratchCardTokenV1} from "src/scratchcard/ScratchCardTokenV1.sol";
import {ScratchCardVRFProvider} from "src/scratchcard/ScratchCardVRFProvider.sol";
import {ScratchCard} from "src/ScratchCard.sol";

contract DeployScratchCard is Script {
    function run() public returns (ScratchCard scratchCard) {
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");
        address vrfCoordinator = vm.envAddress("CHAINLINK_VRF_COORDINATOR");
        uint256 subId = vm.envUint("CHAINLINK_VRF_SUBID");
        bytes32 keyHash = vm.envBytes32("CHAINLINK_VRF_KEYHASH");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy ScratchCardResultV1 contract
        IScratchCardResult scratchCardResult = new ScratchCardResultV1();

        // deploy ScratchCardTokenV1 contract
        IScratchCardToken scratchCardToken = new ScratchCardTokenV1();

        // deploy ScratchCardVRFProvider contract
        IScratchCardRandProvider scratchCardVRFProvider = new ScratchCardVRFProvider(
            vrfCoordinator,
            subId,
            keyHash
        );

        // deploy ScratchCard contract
        scratchCard = new ScratchCard(
            address(scratchCardResult),
            address(scratchCardToken),
            address(scratchCardVRFProvider)
        );

        // set callback address
        scratchCardVRFProvider.setCallbackAddress(address(scratchCard));

        // set allowed minter
        scratchCardToken.setAllowedMinter(address(scratchCard));

        // stop broadcast
        vm.stopBroadcast();

        return scratchCard;
    }
}
