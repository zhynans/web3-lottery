import {
  LotteryDrawnEvent,
  TakeNumbersEvent,
} from "../generated/DailyLottery/DailyLottery";
import { LotteryDrawn, TakeNumber } from "../generated/schema";

export function handleLotteryDrawn(event: LotteryDrawnEvent): void {
  let entity = new LotteryDrawn(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  );
  entity.lotteryNumber = event.params.lotteryNumber;
  entity.winnerNumber = event.params.winnerNumber;
  entity.winner = event.params.winner;
  entity.fee = event.params.fee;
  entity.prize = event.params.prize;
  entity.drawTime = event.params.drawTime;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleTakeNumbers(event: TakeNumbersEvent): void {
  // 平铺 numbers 数组
  for (let i = 0; i < event.params.numbers.length; i++) {
    let entity = new TakeNumber(
      event.transaction.hash.concatI32(event.logIndex.toI32()).concatI32(i),
    );
    entity.lotteryNumber = event.params.lotteryNumber;
    entity.user = event.params.user;

    entity.blockNumber = event.block.number;
    entity.blockTimestamp = event.block.timestamp;
    entity.transactionHash = event.transaction.hash;
    entity.number = event.params.numbers[i];
    entity.save();
  }
}
