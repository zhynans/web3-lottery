// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IScratchCardConfig} from "./interface/IScratchCardConfig.sol";

contract ScratchCardConfigV1 is IScratchCardConfig {
    uint256 private constant PRICE = 0.001 ether; // price of scratch card every time
    uint8 private constant FEE_RATE = 5; // fee rate

    // 价格
    function Price() external pure returns (uint256) {
        return PRICE;
    }

    // 手续费，如果5%，返回5
    function FeeRate() external pure returns (uint8) {
        return FEE_RATE;
    }
}
