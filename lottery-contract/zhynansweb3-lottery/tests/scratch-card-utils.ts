import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  LotteryResult,
  OwnershipTransferred
} from "../generated/ScratchCard/ScratchCard"

export function createLotteryResultEvent(
  user: Address,
  prize: i32,
  amount: BigInt
): LotteryResult {
  let lotteryResultEvent = changetype<LotteryResult>(newMockEvent())

  lotteryResultEvent.parameters = new Array()

  lotteryResultEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  lotteryResultEvent.parameters.push(
    new ethereum.EventParam(
      "prize",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(prize))
    )
  )
  lotteryResultEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return lotteryResultEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent =
    changetype<OwnershipTransferred>(newMockEvent())

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}
