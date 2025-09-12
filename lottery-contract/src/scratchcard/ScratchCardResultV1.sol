// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IScratchCardResult} from "./interface/IScratchCardResult.sol";
import {ScratchCardPrize} from "./ScratchCardDef.sol";

contract ScratchCardResultV1 is IScratchCardResult {
    mapping(ScratchCardPrize prize => uint256 probability) public probabilities;

    constructor() {
        probabilities[ScratchCardPrize.GrandPrize] = 10000; // 0.01%
        probabilities[ScratchCardPrize.SmallPrize] = 100; // 1%
        probabilities[ScratchCardPrize.LuckyPrize] = 20; // 5%
    }

    function getResult(uint256 _randomNumber) external view returns (ScratchCardPrize) {
        if (_randomNumber % probabilities[ScratchCardPrize.GrandPrize] == 0) {
            return ScratchCardPrize.GrandPrize;
        }
        if (_randomNumber % probabilities[ScratchCardPrize.SmallPrize] == 0) {
            return ScratchCardPrize.SmallPrize;
        }
        if (_randomNumber % probabilities[ScratchCardPrize.LuckyPrize] == 0) {
            return ScratchCardPrize.LuckyPrize;
        }
        return ScratchCardPrize.NoPrize;
    }
}
