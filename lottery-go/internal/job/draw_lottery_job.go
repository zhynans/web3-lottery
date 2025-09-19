package job

import (
	"lottery-go/internal/application"
	"lottery-go/internal/base/logx"
)

type DrawLotteryJob struct {
	dailyLotteryApp *application.DailyLotteryApplication
}

func NewDrawLotteryJob(dailyLotteryApp *application.DailyLotteryApplication) *DrawLotteryJob {
	return &DrawLotteryJob{dailyLotteryApp: dailyLotteryApp}
}

func (job *DrawLotteryJob) Run() {
	_, err := job.dailyLotteryApp.Draw()
	if err != nil {
		logx.ErrorF("draw lottery job err: %v", err)
	}
}
