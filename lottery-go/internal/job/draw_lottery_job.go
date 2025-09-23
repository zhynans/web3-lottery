package job

import (
	"lottery-go/internal/application"
	"lottery-go/internal/base/errorx"
	"lottery-go/internal/base/logx"
	"time"
)

type DrawLotteryJob struct {
	records         map[string]*Record // 任务记录数据（可持久化，这里简化处理）
	dailyLotteryApp *application.DailyLotteryApplication
}

type Record struct {
	lotteryNumber uint64
	isDrawn       bool
	tryCount      uint8
}

func NewDrawLotteryJob(dailyLotteryApp *application.DailyLotteryApplication) *DrawLotteryJob {
	records := make(map[string]*Record)
	return &DrawLotteryJob{records: records, dailyLotteryApp: dailyLotteryApp}
}

func (job *DrawLotteryJob) Run() {
	today := time.Now().Format(time.DateOnly)
	logx.Info("drawLotteryJob start.", "today", today)

	// 获取当天的任务记录数据，只有获取lotteryNumber时，才会返回error。
	if record, err := job.getRecord(today); err != nil {
		logx.ErrorF("record not found. %v", err)

		// 网络正常情况下，获取lotteryNumber不可能报错，因此触发报警功能
		job.triggerAlarm()
	} else {
		// 如果已经执行成功，则立即返回
		if record.isDrawn {
			return
		}

		// 执行开奖逻辑
		var suc bool
		if suc, err = job.dailyLotteryApp.Draw(record.lotteryNumber); err != nil {
			logx.ErrorF("draw error: %v", err)
		} else {
			// 如果开奖成功，则更新任务记录状态
			if suc {
				record.isDrawn = true
				logx.Info("draw success.")
			}
		}

		record.tryCount++
		// 如果开奖未完成，且尝试次数达到阈值，则触发业务报警功能
		if !record.isDrawn && record.tryCount >= 2 {
			logx.ErrorF("DrawLotteryJob execute fails. retryCount: %d, %v", record.tryCount, err)
			job.triggerAlarm()
		}
	}
}

func (job *DrawLotteryJob) getRecord(today string) (*Record, error) {
	if job.records[today] == nil {
		// 获取当前的lotteryNumber
		lotteryNumber, err := job.dailyLotteryApp.CurrentLotteryNumber()
		if err != nil {
			return nil, errorx.Wrap("failed to get lotteryNumber", err)
		}
		job.records[today] = &Record{lotteryNumber: lotteryNumber, isDrawn: false, tryCount: 0}
	}

	return job.records[today], nil
}

func (job *DrawLotteryJob) triggerAlarm() {
	// todo
}
