package server

import (
	"github.com/robfig/cron/v3"
	"lottery-go/internal/job"
)

func NewJob(registryJobs job.RegistryJobs) (*cron.Cron, error) {
	c := cron.New(
		cron.WithChain(job.Recovery),
	)

	if err := registryJobs(c); err != nil {
		return nil, err
	}

	return c, nil
}
