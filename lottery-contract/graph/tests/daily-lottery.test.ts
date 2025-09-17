import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { LotteryDrawn } from "../generated/schema"
import { LotteryDrawn as LotteryDrawnEvent } from "../generated/DailyLottery/DailyLottery"
import { handleLotteryDrawn } from "../src/daily-lottery"
import { createLotteryDrawnEvent } from "./daily-lottery-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#tests-structure

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let lotteryNumber = BigInt.fromI32(234)
    let winningNumber = BigInt.fromI32(234)
    let winner = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let fee = BigInt.fromI32(234)
    let prize = BigInt.fromI32(234)
    let newLotteryDrawnEvent = createLotteryDrawnEvent(
      lotteryNumber,
      winningNumber,
      winner,
      fee,
      prize
    )
    handleLotteryDrawn(newLotteryDrawnEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#write-a-unit-test

  test("LotteryDrawn created and stored", () => {
    assert.entityCount("LotteryDrawn", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "LotteryDrawn",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "lotteryNumber",
      "234"
    )
    assert.fieldEquals(
      "LotteryDrawn",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "winningNumber",
      "234"
    )
    assert.fieldEquals(
      "LotteryDrawn",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "winner",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "LotteryDrawn",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "fee",
      "234"
    )
    assert.fieldEquals(
      "LotteryDrawn",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "prize",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#asserts
  })
})
