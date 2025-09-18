import { parseAbi } from "viem";

export const dailyLotteryAbi = parseAbi([
  "function lotteryNumber() view returns (uint64)",
  "function takeNumbers(uint64 nums) payable",
  "event TakeNumbersEvent(uint64 indexed lotteryNumber, address indexed user, uint64[] numbers)",
]);

export const scratchCardAbi = parseAbi([
  "function fund() payable",
  "function scratchCard() payable",
  "event LotteryResultEvent(address indexed user,  uint256 indexed timestamp, uint8 indexed prize, uint256 amount, uint256 randomNumber)",
]);
