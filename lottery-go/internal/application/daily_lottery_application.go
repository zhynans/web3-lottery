package application

import (
	"lottery-go/internal/contract"
)

type DailyLotteryApplication struct {
	dailyLotteryContract *contract.DailyLotteryContract
}

func NewDailyLotteryApplication(dailyLotteryContract *contract.DailyLotteryContract) *DailyLotteryApplication {
	return &DailyLotteryApplication{dailyLotteryContract: dailyLotteryContract}
}

func (app *DailyLotteryApplication) Draw(lotteryNumber uint64) (bool, error) {
	// 检查合约状态，如果已经完成，则立即返回
	state, err := app.dailyLotteryContract.DrawState(lotteryNumber)
	if err != nil {
		return false, err
	}

	// 如果已开奖，更新状态
	// 如果正在开奖，不做处理，直接返回false
	// 如果还没开奖，触发合约开奖函数
	isDraw := false
	if state == contract.Drawn {
		isDraw = true
	} else if state == contract.NotDrawn {
		err = app.dailyLotteryContract.Draw(lotteryNumber)
		if err == nil {
			isDraw = true
		}
	}

	return isDraw, err
}

func (app *DailyLotteryApplication) CurrentLotteryNumber() (uint64, error) {
	return app.dailyLotteryContract.LotteryNumber()
}
