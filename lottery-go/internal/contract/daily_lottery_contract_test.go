package contract

import (
	"lottery-go/internal/config"
	"lottery-go/internal/pkg/eth"
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
		t.Logf("Draw() error: %v", err)

		// 验证错误解析是否正常工作
		if contractErr, ok := err.(*eth.ContractError); ok {
			t.Logf("Parsed contract error - Type: %s, Message: %s", contractErr.Type, contractErr.Message)
			// 期望的错误类型应该是 MinDrawIntervalNotMet
			if contractErr.Type != "MinDrawIntervalNotMet" {
				t.Errorf("Expected error type 'MinDrawIntervalNotMet', got '%s'", contractErr.Type)
			}
		} else {
			t.Logf("Error is not a ContractError: %T", err)
		}
	}
}
