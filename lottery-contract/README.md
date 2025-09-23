## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Test

```shell
$ forge test
```

### Local Deploy

Foundry 默认 不会自动加载 .env，需要在 shell 中加载：

```
$ source .env
```

anvil
使用自定义的助记词来生成账户。在不同 Anvil 实例之间复用相同账户非常有用。

```shell
$ anvil --port 8545 --chain-id 31337 --mnemonic "test test test test test test test test test test test junk"
```

本地部署脚本脚本：
Anvil本地链

````shell
$ forge script script/LocalAllDeployDailyLottery.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
$ forge script script/LocalAllDeployScratchCard.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast
```

本地The Graph

```shell
$ docker-compose up

$ graph create zhynans-web3-lottery --node http://localhost:8020
$ graph deploy --node http://localhost:8020 zhynans-web3-lottery --network anvil

$ graph remove --node http://localhost:8020/ zhynans-web3-lottery

$ docker-compose down
````

sepolia部署脚本：

```shell
$ forge script --chain sepolia script/AllDeployDailyLottery.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast --verify
$ forge script --chain sepolia script/AllDeployScratchCard.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast --verify

$ forge script --chain sepolia script/DeployDailyLottery.s.sol --rpc-url $CHAIN_RPC_URL -vvvv --broadcast --verify
```
