## lottery-contract

### 项目介绍

去中心化彩票项目的合约代码，分为两部分：天天有奖 和 刮刮乐。

### 部署命令

Foundry 默认 不会自动加载 .env，需要在 shell 中加载：

```
$ source .env
```

如果要使用`.env.local`或者`.env.test`，最好是复制内容覆盖`.env`文件，再执行部署脚本。因为`source .env.local`后的环境变量在`forge script`是读取不到的。

anvil
使用自定义的助记词来生成账户。在不同 Anvil 实例之间复用相同账户非常有用。

```shell
$ anvil --port 8545 --chain-id 31337 --mnemonic "test test test test test test test test test test test junk"
```

本地部署脚本脚本：
Anvil本地链

````shell
# dailyLottery
$ forge script script/dailylottery/DeployDailyLotteryConfigV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/dailylottery/DeployDailyLotteryNumberLogicV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/dailylottery/DeployDailyLotteryTokenV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/dailylottery/DeployDailyLotteryVRFProvider.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/dailylottery/DeployDailyLotteryV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/dailylottery/DeployDailyLotteryProxy.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast

# scratchCard
$ forge script script/scratchcard/DeployScratchCardConfigV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/scratchcard/DeployScratchCardResultV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/scratchcard/DeployScratchCardTokenV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/scratchcard/DeployScratchCardV1.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/scratchcard/DeployScratchCardVRFProvider.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/scratchcard/DeployScratchCardProxy.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
```

本地The Graph

```shell
$ docker-compose up

$ graph create zhynans-web3-lottery --node http://localhost:8020
$ graph deploy --node http://localhost:8020 zhynans-web3-lottery --network anvil

$ graph remove --node http://localhost:8020/ zhynans-web3-lottery

$ docker-compose down
````
