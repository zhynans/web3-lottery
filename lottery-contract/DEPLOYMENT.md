# ScratchCard 部署指南

## 环境变量设置

在部署之前，需要设置以下环境变量：

```bash
# 部署者私钥
export PRIVATE_KEY_1="your_private_key_here"

# Chainlink VRF 配置
export CHAINLINK_VRF_COORDINATOR="0x..."
export CHAINLINK_VRF_SUBID="your_subscription_id"
export CHAINLINK_VRF_KEYHASH="0x..."
```

## 部署命令

### 1. 部署到测试网络

```bash
forge script script/DeployScratchCard.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY_1 --broadcast --verify
```

### 2. 部署到主网络

```bash
forge script script/DeployScratchCard.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY_1 --broadcast --verify
```

### 3. 本地测试

```bash
forge script script/DeployScratchCard.s.sol --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## 部署流程

部署脚本会按以下顺序执行：

1. **部署 ScratchCardResultV1**: 处理刮刮卡结果逻辑
2. **部署 ScratchCardTokenV1**: ERC721 代币合约
3. **部署 ScratchCardVRFProvider**: Chainlink VRF 提供者
4. **部署 ScratchCard**: 主合约
5. **配置回调地址**: 设置 VRF 提供者的回调地址
6. **设置铸造权限**: 允许主合约铸造代币

## 部署后配置

部署完成后，需要：

1. **资助合约**: 调用 `fund()` 函数向合约存入以太坊
2. **配置 VRF 订阅**: 确保 Chainlink VRF 订阅有足够的 LINK 代币
3. **添加消费者**: 将 VRF 提供者添加到 VRF 订阅中

## 验证部署

运行集成测试来验证部署：

```bash
forge test --match-contract ScratchCardIntegrationTest -v
```

## 注意事项

- 确保部署账户有足够的以太坊支付 gas 费用
- VRF 订阅需要有足够的 LINK 代币
- 在生产环境中部署前，请在测试网络上充分测试
