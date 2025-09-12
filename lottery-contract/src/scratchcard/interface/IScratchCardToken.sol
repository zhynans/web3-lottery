// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ScratchCardPrize} from "../ScratchCardDef.sol";

interface IScratchCardToken {
    function safeMint(address to, ScratchCardPrize prize) external returns (uint256);

    function setAllowedMinter(address minter) external;
}
