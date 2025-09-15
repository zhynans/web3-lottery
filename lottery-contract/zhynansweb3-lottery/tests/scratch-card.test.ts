import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { LotteryResult } from "../generated/schema"
import { LotteryResult as LotteryResultEvent } from "../generated/ScratchCard/ScratchCard"
import { handleLotteryResult } from "../src/scratch-card"
import { createLotteryResultEvent } from "./scratch-card-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#tests-structure

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let user = Address.fromString("0x0000000000000000000000000000000000000001")
    let prize = 123
    let amount = BigInt.fromI32(234)
    let newLotteryResultEvent = createLotteryResultEvent(user, prize, amount)
    handleLotteryResult(newLotteryResultEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#write-a-unit-test

  test("LotteryResult created and stored", () => {
    assert.entityCount("LotteryResult", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "LotteryResult",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "user",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "LotteryResult",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "prize",
      "123"
    )
    assert.fieldEquals(
      "LotteryResult",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "amount",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#asserts
  })
})
