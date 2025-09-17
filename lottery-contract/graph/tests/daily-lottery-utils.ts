import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  LotteryDrawn,
  OwnershipTransferred
} from "../generated/DailyLottery/DailyLottery"

export function createLotteryDrawnEvent(
  lotteryNumber: BigInt,
  winningNumber: BigInt,
  winner: Address,
  fee: BigInt,
  prize: BigInt
): LotteryDrawn {
  let lotteryDrawnEvent = changetype<LotteryDrawn>(newMockEvent())

  lotteryDrawnEvent.parameters = new Array()

  lotteryDrawnEvent.parameters.push(
    new ethereum.EventParam(
      "lotteryNumber",
      ethereum.Value.fromUnsignedBigInt(lotteryNumber)
    )
  )
  lotteryDrawnEvent.parameters.push(
    new ethereum.EventParam(
      "winningNumber",
      ethereum.Value.fromUnsignedBigInt(winningNumber)
    )
  )
  lotteryDrawnEvent.parameters.push(
    new ethereum.EventParam("winner", ethereum.Value.fromAddress(winner))
  )
  lotteryDrawnEvent.parameters.push(
    new ethereum.EventParam("fee", ethereum.Value.fromUnsignedBigInt(fee))
  )
  lotteryDrawnEvent.parameters.push(
    new ethereum.EventParam("prize", ethereum.Value.fromUnsignedBigInt(prize))
  )

  return lotteryDrawnEvent
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
