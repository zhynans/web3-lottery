package logx

import (
	"github.com/spf13/viper"
	"lottery-go/internal/config"
)

func init() {
	loader := &ConfigLoader{}
	config.Register("log", loader)
}

var cfg *Cfg
var defaultLogger ILogger

// =========== config info ===========

type Cfg struct {
	Default LoggerCfg
}

// LoggerCfg 日志打印器配置信息
type LoggerCfg struct {
	Level    string
	FilePath string
}

// ========== ConfigLoader ==========

type ConfigLoader struct{}

// Load load log config info
func (loader *ConfigLoader) Load(conf *viper.Viper) error {
	err := conf.Unmarshal(&cfg)
	if err != nil {
		return err
	}

	// init default logger
	defaultLogger = NewLogger(&cfg.Default)
	return nil
}
