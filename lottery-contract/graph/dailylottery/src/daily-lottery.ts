import {
  LotteryDrawnEvent,
  TakeNumbersEvent,
} from "../generated/DailyLottery/DailyLottery";
import { LotteryDrawn, TakeNumbers } from "../generated/schema";

export function handleLotteryDrawn(event: LotteryDrawnEvent): void {
  let entity = new LotteryDrawn(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  );
  entity.lotteryNumber = event.params.lotteryNumber;
  entity.winningNumber = event.params.winningNumber;
  entity.winner = event.params.winner;
  entity.fee = event.params.fee;
  entity.prize = event.params.prize;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleTakeNumbers(event: TakeNumbersEvent): void {
  let entity = new TakeNumbers(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  );
  entity.lotteryNumber = event.params.lotteryNumber;
  entity.user = event.params.user;
  entity.numbers = event.params.numbers;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
