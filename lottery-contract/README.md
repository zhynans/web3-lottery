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

### Deploy

Foundry 默认 不会自动加载 .env，需要在 shell 中加载：

```
$ source .env
```

部署脚本：

```shell
$ forge script --chain sepolia script/DailyLottery.s.sol --fork-url $SEPOLIA_RPC_URL -vvvv --broadcast --verify
```
