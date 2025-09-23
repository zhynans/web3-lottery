package job

import (
	"github.com/robfig/cron/v3"
	"lottery-go/internal/base/errorx"
)

type RegistryJobs func(c *cron.Cron) error

func NewRegistryJobs(drawLotteryJob *DrawLotteryJob) RegistryJobs {
	return func(c *cron.Cron) error {
		// 天天有奖的开奖任务，任务执行时间：每天凌晨0点，每10分钟执行一次
		if _, err := c.AddJob("0/10 0 * * *", drawLotteryJob); err != nil {
			return errorx.Wrap("fails to add job", err, "name", "drawLotteryJob")
		}

		return nil
	}
}
