// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IScratchCardConfig {
    // 价格
    function Price() external view returns (uint256);

    // 手续费，如果5%，返回5
    function FeeRate() external view returns (uint8);
}
