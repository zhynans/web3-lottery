import {
  LotteryDrawn as LotteryDrawnEvent,
  OwnershipTransferred as OwnershipTransferredEvent
} from "../generated/DailyLottery/DailyLottery"
import { LotteryDrawn, OwnershipTransferred } from "../generated/schema"

export function handleLotteryDrawn(event: LotteryDrawnEvent): void {
  let entity = new LotteryDrawn(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.lotteryNumber = event.params.lotteryNumber
  entity.winningNumber = event.params.winningNumber
  entity.winner = event.params.winner
  entity.fee = event.params.fee
  entity.prize = event.params.prize

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
