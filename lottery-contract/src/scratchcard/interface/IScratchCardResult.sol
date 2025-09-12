// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ScratchCardPrize} from "../ScratchCardDef.sol";

interface IScratchCardResult {
    function getResult(uint256 _randomNumber) external view returns (ScratchCardPrize);
}
