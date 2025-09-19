package application

import (
	"lottery-go/internal/base/errorx"
	"lottery-go/internal/contract"
	"time"
)

type DailyLotteryApplication struct {
	records              map[string]*Record // 可持久化，这里简化处理
	dailyLotteryContract *contract.DailyLotteryContract
}

type Record struct {
	lotteryNumber uint64
	isDrawn       bool
	tryCount      uint8
}

func NewDailyLotteryApplication(dailyLotteryContract *contract.DailyLotteryContract) *DailyLotteryApplication {
	records := make(map[string]*Record)
	return &DailyLotteryApplication{records: records, dailyLotteryContract: dailyLotteryContract}
}

func (app *DailyLotteryApplication) Draw() (bool, error) {
	// 判断
	record, err := app.getRecord()
	if err != nil {
		return false, err
	}
	if record.isDrawn {
		return true, nil
	}

	// 更新尝试次数
	record.tryCount++

	// 检查合约状态，如果已经完成，则立即返回
	state, err := app.dailyLotteryContract.DrawState(record.lotteryNumber)
	if err != nil {
		return false, err
	}

	// 如果已开奖，更新状态
	// 如果正在开奖，不做处理
	// 如果还没开奖，触发合约开奖函数
	if state == contract.Drawn {
		record.isDrawn = true
	} else if state == contract.NotDrawn {
		err = app.dailyLotteryContract.Draw()
		if err == nil {
			record.isDrawn = true
		}
	}

	// 如果开奖未完成，且尝试次数达到阈值，则触发业务报警功能
	if !record.isDrawn && record.tryCount >= 2 {
		// todo
	}

	return record.isDrawn, err
}

func (app *DailyLotteryApplication) getRecord() (*Record, error) {
	today := time.Now().Format(time.DateOnly)

	if app.records[today] == nil {
		// 获取当前的lotteryNumber
		lotteryNumber, err := app.dailyLotteryContract.LotteryNumber()
		if err != nil {
			return nil, errorx.Wrap("failed to get lotteryNumber", err)
		}
		app.records[today] = &Record{lotteryNumber: lotteryNumber, isDrawn: false, tryCount: 0}
	}

	return app.records[today], nil
}
