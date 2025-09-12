// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IDailyLotteryNumberLogic} from "./interface/IDailyLotteryNumberLogic.sol";

contract DailyLotteryNumberLogicV1 is IDailyLotteryNumberLogic {
    // current number, start from 1, increment by 1.
    // it will reset to 1 when the lottery number is changed.
    uint64 public currentNumber;

    function initNumberLogic() external {
        currentNumber = 1;
    }

    function canDraw() external view returns (bool) {
        return currentNumber > 1;
    }

    function takeNumbers(uint64 nums) external returns (uint64[] memory) {
        uint64[] memory numbers = new uint64[](nums);
        for (uint64 i = 0; i < numbers.length; i++) {
            numbers[i] = currentNumber;
            currentNumber++;
        }

        return numbers;
    }

    function getWinnerNumber(uint256 randomNumber) external view returns (uint64) {
        return uint64((randomNumber % (currentNumber - 1)) + 1); // random value in [1, currentNumber-1]
    }
}
