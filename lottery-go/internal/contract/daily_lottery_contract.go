// Package contract 提供与智能合约交互的功能
package contract

import (
	"lottery-go/internal/config"
	"lottery-go/internal/pkg/eth"
)

type DailyLotteryContract struct {
	config *config.Contract
}

type DrawState uint8

const (
	NotDrawn DrawState = iota
	Drawing
	Drawn
)

var drawStates = map[uint8]DrawState{
	0: NotDrawn,
	1: Drawing,
	2: Drawn,
}

func NewDailyLotteryContract() *DailyLotteryContract {
	return &DailyLotteryContract{config: config.DailyLottery()}
}

// LotteryNumber current lottery number
func (contract *DailyLotteryContract) LotteryNumber() (uint64, error) {
	var lotteryNumber uint64
	err := eth.CallContractView(&eth.CallContext{
		RpcUrl:   contract.config.RpcUrl,
		Address:  contract.config.Address,
		Abi:      dailyLotteryContractABI,
		FuncName: "lotteryNumber",
	}, &lotteryNumber)
	if err != nil {
		return 0, err
	}
	return lotteryNumber, nil
}

// DrawState 获取开奖状态
func (contract *DailyLotteryContract) DrawState(lotteryNumber uint64) (DrawState, error) {
	var drawState uint8
	err := eth.CallContractView(&eth.CallContext{
		RpcUrl:   contract.config.RpcUrl,
		Address:  contract.config.Address,
		Abi:      dailyLotteryContractABI,
		FuncName: "getDrawState",
	}, &drawState, lotteryNumber)
	if err != nil {
		return 0, err
	}
	return drawStates[drawState], nil
}

// Draw 执行抽奖交易
func (contract *DailyLotteryContract) Draw(lotteryNumber uint64) error {
	_, err := eth.SendTransaction(&eth.TransactionContext{
		RpcUrl:     contract.config.RpcUrl,
		Address:    contract.config.Address,
		Abi:        dailyLotteryContractABI,
		FuncName:   "drawLottery",
		PrivateKey: contract.config.PrivateKey,
	}, lotteryNumber)

	if err != nil {
		// 检查是否是合约错误
		if contractErr := eth.ParseContractError(dailyLotteryErrorABI, err); contractErr != nil {
			return contractErr
		}
		return err
	}
	return nil
}

// IsDrawn 检查是否已抽奖完成，供application层使用
func (contract *DailyLotteryContract) IsDrawn(lotteryNumber uint64) bool {
	drawState, err := contract.DrawState(lotteryNumber)
	if err != nil {
		return false
	}
	return drawState > 0
}
