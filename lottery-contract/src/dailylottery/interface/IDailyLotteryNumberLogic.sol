// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IDailyLotteryNumberLogic {
    // initialize number logic
    function initNumberLogic() external;

    // check if can draw
    function canDraw() external view returns (bool);

    // take numbers
    function takeNumbers(uint64 nums) external returns (uint64[] memory);

    // get winner number
    function getWinnerNumber(uint256 randomNumber) external view returns (uint64);
}
