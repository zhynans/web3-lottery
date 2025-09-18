// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ScratchCard} from "src/ScratchCard.sol";
import {ScratchCardResultV1} from "src/scratchcard/ScratchCardResultV1.sol";
import {ScratchCardTokenV1} from "src/scratchcard/ScratchCardTokenV1.sol";
import {ScratchCardVRFProvider} from "src/scratchcard/ScratchCardVRFProvider.sol";
import {AllDeployScratchCard} from "script/AllDeployScratchCard.s.sol";
import {IScratchCardRandProvider} from "src/scratchcard/interface/IScratchCardRand.sol";

contract ScratchCardIntegrationTest is Test {
    ScratchCard scratchCard;
    ScratchCardResultV1 scratchCardResult;
    ScratchCardTokenV1 scratchCardToken;
    ScratchCardVRFProvider scratchCardVRFProvider;

    function setUp() public {}

    function test_ScratchCardWorkflow() public {}
}
