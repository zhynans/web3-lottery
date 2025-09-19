package config

import (
	"github.com/spf13/pflag"
	"log/slog"
)

// env 环境
var env = pflag.String("env", "dev", "Environment: dev or prod")

func init() {
	pflag.Parse()
	slog.Info("loadAppConfig.", "env", *env)

	// register Contracts Loader
	Register("contracts", &ContractsLoader{})
}
