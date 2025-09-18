package server

import (
	"github.com/robfig/cron/v3"
	"lottery-go/internal/base/logx"
)

func NewApp(cron *cron.Cron) *App {
	return &App{cron: cron}
}

type App struct {
	cron *cron.Cron
}

func (app *App) Run() {
	// 启动定时任务
	app.cron.Start()

	logx.Info("app started")
	select {} // 阻塞主程序退出
}
