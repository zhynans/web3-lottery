package config

import (
	"fmt"
	"github.com/spf13/viper"
)

type Loader interface {
	Load(conf *viper.Viper) error
}

var loaders = make(map[string]Loader)

func Register(name string, loader Loader) {
	loaders[name] = loader
}

func LoadAll() error {
	viperConfig := viper.New()
	viperConfig.AddConfigPath("configs")
	viperConfig.SetConfigName(fmt.Sprintf("application-%s", *env))
	viperConfig.SetConfigType("yaml")

	err := viperConfig.ReadInConfig()
	if err != nil {
		panic(fmt.Errorf("use Viper ReadInConfig Fatal error Global err:%s", err))
	}

	for name, loader := range loaders {
		// 获取各组件配置
		cfg := viperConfig.Sub(name)

		if err := loader.Load(cfg); err != nil {
			return fmt.Errorf("load config for %s failed: %w", name, err)
		}
	}
	return nil
}
