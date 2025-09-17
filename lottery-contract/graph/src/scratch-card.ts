import {
  LotteryResultEvent,
  ScratchCardEvent,
} from "../generated/ScratchCard/ScratchCard";
import { LotteryResult, ScratchCard } from "../generated/schema";

export function handleLotteryResult(event: LotteryResultEvent): void {
  let entity = new LotteryResult(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  );
  entity.user = event.params.user;
  entity.prize = event.params.prize;
  entity.amount = event.params.amount;
  entity.timestamp = event.params.timestamp;
  entity.randomNumber = event.params.randomNumber;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleScratchCard(event: ScratchCardEvent): void {
  let entity = new ScratchCard(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  );
  entity.user = event.params.user;
  entity.value = event.params.value;
  entity.timestamp = event.params.timestamp;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
