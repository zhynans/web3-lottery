package job

import (
	"github.com/google/wire"
	"github.com/robfig/cron/v3"
)

var ProviderSet = wire.NewSet(NewRegistryJobs)

type RegistryJobs func(c *cron.Cron) error

func NewRegistryJobs() RegistryJobs {
	return func(c *cron.Cron) error {
		// 定时开奖任务
		//if _, err := c.AddJob("@every 1m", wechatAccessTokenJob); err != nil {
		//	return errorx.Wrap("fails to add job", err, "name", "drawLotteryJob")
		//}

		return nil
	}
}
