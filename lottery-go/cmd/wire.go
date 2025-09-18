//go:build wireinject
// +build wireinject

package main

import (
	"github.com/google/wire"
	"lottery-go/internal/job"
	"lottery-go/internal/server"
)

func initApp() (*server.App, error) {
	wire.Build(job.ProviderSet, server.ProviderSet)

	return &server.App{}, nil
}
