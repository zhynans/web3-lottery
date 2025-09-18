package job

import (
	"github.com/robfig/cron/v3"
	"lottery-go/internal/base/logx"
	"lottery-go/internal/base/stack"
)

// Recovery 定时任务恢复中间件
func Recovery(next cron.Job) cron.Job {
	return cron.FuncJob(func() {
		defer func() {
			if err := recover(); err != nil {
				logx.ErrorF("任务发生panic: err: %v, stack: %v", err, stack.GetStackTrace(3))
			}
		}()

		next.Run()
	})
}
