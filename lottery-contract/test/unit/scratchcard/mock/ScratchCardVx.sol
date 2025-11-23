// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ScratchCardV1} from "src/scratchcard/ScratchCardV1.sol";

contract ScratchCardVx is ScratchCardV1 {
    function version() external pure returns (string memory) {
        return "Vx";
    }
}
