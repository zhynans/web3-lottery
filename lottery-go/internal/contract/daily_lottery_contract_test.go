package contract

import (
	"lottery-go/internal/config"
	"testing"
)

var (
	rpcUrl     = "https://eth-sepolia.g.alchemy.com/v2/y8Q8CNRbC_f36_VtVTY1a"
	address    = "0x5e9Af14b431196FC988C1DC7eD2762a93b5F96C6"
	privateKey = "303c46fd467fd61d2b3b292cbae01cd67936a762b5ca8528a2cfd3511fb216b8"
)

func DailyLotteryContractConfig() *config.Contract {
	return &config.Contract{
		RpcUrl:     rpcUrl,
		Address:    address,
		PrivateKey: privateKey,
	}
}

func TestDailyLotteryContract_LotteryNumber(t *testing.T) {
	contract := &DailyLotteryContract{config: DailyLotteryContractConfig()}
	lotteryNumber, err := contract.LotteryNumber()
	if err != nil {
		t.Fatalf("fails to LotteryNumber(), %v", err)
	}

	t.Logf("Lottery Number: %d, ", lotteryNumber)
}

func TestDailyLotteryContract_DrawState(t *testing.T) {
	contract := &DailyLotteryContract{config: DailyLotteryContractConfig()}

	// 使用彩票号码获取抽奖状态
	drawState, err := contract.DrawState(1)
	if err != nil {
		t.Fatalf("fails to get DrawState(), %v", err)
	}

	t.Logf("Draw State: %d", drawState)
}

func TestDailyLotteryContract_Draw(t *testing.T) {
	contract := &DailyLotteryContract{config: DailyLotteryContractConfig()}

	err := contract.Draw()
	if err != nil {
		t.Fatalf("fails to get Draw(), %v", err)
	}
}
