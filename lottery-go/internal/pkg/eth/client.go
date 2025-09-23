// Package eth 提供以太坊合约交互的通用封装
package eth

import (
	"context"
	"github.com/ethereum/go-ethereum/core/types"
	"lottery-go/internal/base/errorx"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

type CallContext struct {
	RpcUrl   string
	Address  string
	Abi      string
	FuncName string
}

type TransactionContext struct {
	RpcUrl     string
	Address    string
	Abi        string
	FuncName   string
	PrivateKey string
}

// CallContractView 通用的合约view函数调用方法
func CallContractView(ctx *CallContext, result interface{}, args ...interface{}) error {
	// 连接节点
	client, err := ethclient.Dial(ctx.RpcUrl)
	if err != nil {
		return errorx.Wrap("failed to connect Ethereum rpc client", err)
	}
	defer client.Close()

	// 目标合约地址
	contractAddr := common.HexToAddress(ctx.Address)

	// 解析 ABI
	parsedABI, err := abi.JSON(strings.NewReader(ctx.Abi))
	if err != nil {
		return errorx.Wrap("failed to parse contract ABI", err)
	}

	// 获取函数调用数据
	data, err := parsedABI.Pack(ctx.FuncName, args...)
	if err != nil {
		return errorx.Wrap("failed to pack function call", err, "function", ctx.FuncName)
	}

	// 发送 call
	msg := ethereum.CallMsg{
		To:   &contractAddr,
		Data: data,
	}

	res, err := client.CallContract(context.Background(), msg, nil)
	if err != nil {
		return errorx.Wrap("failed to call function", err, "function", ctx.FuncName)
	}

	// 解析返回结果
	err = parsedABI.UnpackIntoInterface(result, ctx.FuncName, res)
	if err != nil {
		return errorx.Wrap("failed to unpack result", err, "function", ctx.FuncName)
	}

	return nil
}

// SendTransaction 通用的合约交易发送方法
func SendTransaction(ctx *TransactionContext, args ...interface{}) (*types.Receipt, error) {
	// 连接节点
	client, err := ethclient.Dial(ctx.RpcUrl)
	if err != nil {
		return nil, errorx.Wrap("failed to connect Ethereum rpc client", err)
	}
	defer client.Close()

	// 目标合约地址
	contractAddr := common.HexToAddress(ctx.Address)

	// 解析私钥
	privateKey, err := crypto.HexToECDSA(ctx.PrivateKey)
	if err != nil {
		return nil, errorx.Wrap("failed to parse private key", err)
	}

	// 获取链ID
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		return nil, errorx.Wrap("failed to get network ID", err)
	}

	// 创建认证
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, errorx.Wrap("failed to create transactor", err)
	}

	// 解析 ABI
	parsedABI, err := abi.JSON(strings.NewReader(ctx.Abi))
	if err != nil {
		return nil, errorx.Wrap("failed to parse contract ABI", err)
	}

	// 创建合约实例
	contractInstance := bind.NewBoundContract(contractAddr, parsedABI, client, client, client)

	// 发送交易
	tx, err := contractInstance.Transact(auth, ctx.FuncName, args...)
	if err != nil {
		return nil, errorx.Wrap("failed to send transaction", err, "function", ctx.FuncName)
	}

	// 等待交易确认
	receipt, err := bind.WaitMined(context.Background(), client, tx)
	if err != nil {
		return nil, errorx.Wrap("failed to wait for transaction confirmation", err)
	}

	// 检查交易状态
	if receipt.Status != 1 {
		return nil, errorx.New("transaction failed")
	}

	return receipt, nil
}
