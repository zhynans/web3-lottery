import {
  LotteryResult as LotteryResultEvent,
  OwnershipTransferred as OwnershipTransferredEvent
} from "../generated/ScratchCard/ScratchCard"
import { LotteryResult, OwnershipTransferred } from "../generated/schema"

export function handleLotteryResult(event: LotteryResultEvent): void {
  let entity = new LotteryResult(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.user = event.params.user
  entity.prize = event.params.prize
  entity.amount = event.params.amount

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
