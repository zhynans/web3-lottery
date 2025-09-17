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
import {VRFCoordinatorV2_5Mock} from "script/mock/VRFCoordinatorV2_5Mock.sol";

contract AllDeployScratchCard is Script {
    uint96 public constant BASE_FEE = 0.1 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;
    bytes32 public constant KEY_HASH =
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    function run() public returns (ScratchCard scratchCard) {
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy ScratchCardResultV1 contract
        IScratchCardResult scratchCardResult = new ScratchCardResultV1();

        // deploy ScratchCardTokenV1 contract
        IScratchCardToken scratchCardToken = new ScratchCardTokenV1();

        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE_LINK,
            WEI_PER_UNIT_LINK
        );
        // Create subscription
        uint256 subId = vrfCoordinator.createSubscription();

        // deploy ScratchCardVRFProvider contract
        IScratchCardRandProvider scratchCardVRFProvider = new ScratchCardVRFProvider(
            address(vrfCoordinator),
            subId,
            KEY_HASH
        );

        // Add consumer to subscription
        vrfCoordinator.addConsumer(subId, address(scratchCardVRFProvider));

        // Fund subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);

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
