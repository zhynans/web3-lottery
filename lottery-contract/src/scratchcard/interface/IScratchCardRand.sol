// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IScratchCardRandProvider {
    function requestRandomNumbers(address _user) external;
}

interface IScratchCardRandCallback {
    function callbackFromRand(address _user, uint256 _randomNumber) external;
}
