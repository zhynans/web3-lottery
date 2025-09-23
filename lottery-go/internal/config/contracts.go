package config

import (
	"github.com/spf13/viper"
)

// >>>>>>>>>>>>>>> contracts config info <<<<<<<<<<<<

type Contracts struct {
	DailyLottery *Contract `mapstructure:"daily-lottery"`
}

type Contract struct {
	RpcUrl     string
	Address    string
	PrivateKey string
}

var contracts *Contracts

// DailyLottery get config info of the dailyLottery contract
func DailyLottery() *Contract {
	return contracts.DailyLottery
}

// >>>>>>>>>>>>>>> Contracts Loader <<<<<<<<<<<<<

type ContractsLoader struct{}

func (loader *ContractsLoader) Load(conf *viper.Viper) error {
	if err := conf.Unmarshal(&contracts); err != nil {
		return err
	}

	return nil
}
