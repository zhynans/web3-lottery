package contract

import "github.com/google/wire"

var ProviderSet = wire.NewSet(NewDailyLotteryContract)
