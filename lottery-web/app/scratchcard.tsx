"use client";

import { useState } from "react";
import { waitForTransactionReceipt } from "wagmi/actions";
import { useBalance, useAccount, useWriteContract } from "wagmi";
import { parseEther, formatEther, parseAbi, decodeEventLog } from "viem";
import { getConfig } from "./wagmi";
import { ScratchCard } from "./components/ScratchCard";
import toast from "react-hot-toast";

// 合约地址和ABI（这里需要根据实际合约地址和ABI进行配置）
const CONTRACT_ADDRESS = process.env
  .NEXT_PUBLIC_CONTRACT_ADDR_SCRATCHCARD as `0x${string}`;
const CONTRACT_DEPLOYER = process.env
  .NEXT_PUBLIC_CONTRACT_DEPLOYER as `0x${string}`;

// 简化的合约ABI，包含获取奖池金额和充值功能
const CONTRACT_ABI = parseAbi(["function fund() payable"]);

// 刮刮乐刮奖功能组件
export function ScratchCardDraw() {
  // 钱包和合约相关
  const { address, isConnected } = useAccount();
  const { writeContractAsync } = useWriteContract();

  const [fundingAmount, setFundingAmount] = useState("");
  const [isFunding, setIsFunding] = useState(false);

  // 读取奖池金额
  const { data: poolBalance } = useBalance({
    address: CONTRACT_ADDRESS,
    query: {
      enabled: !!CONTRACT_ADDRESS, // 只有当合约地址存在时才启用查询
      refetchInterval: 5000, // 每5秒刷新一次
    },
  });

  // 检查是否为合约部署者
  const isDeployer =
    address &&
    CONTRACT_DEPLOYER &&
    address.toLowerCase() === CONTRACT_DEPLOYER.toLowerCase();

  // 充值奖池处理函数
  const handleFundPrizePool = async () => {
    if (!fundingAmount || !CONTRACT_ADDRESS) return;

    if (!isConnected) {
      toast.error("请连接钱包");
      return;
    }

    try {
      setIsFunding(true);

      // send fund transaction
      const hash = await writeContractAsync({
        abi: CONTRACT_ABI,
        address: CONTRACT_ADDRESS as `0x${string}`,
        functionName: "fund",
        value: parseEther(fundingAmount),
      });

      // wait for transaction receipt
      const receipt = await waitForTransactionReceipt(getConfig(), { hash });
      if (receipt.status !== "success") {
        throw new Error("充值交易未成功，请稍后重试");
      } else {
        toast.success("充值成功");
        setFundingAmount("");
      }
    } catch (error) {
      toast.error("充值失败");
    } finally {
      setIsFunding(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6 min-h-[480px] flex flex-col">
      <h2 className="text-2xl font-bold text-gray-800 mb-6 text-center">
        刮刮乐
      </h2>

      {/* 内容区域 */}
      <div className="space-y-4 flex-1 flex flex-col justify-center">
        {/* 奖池金额显示区域 */}
        <div className="text-center mb-6">
          <div className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white p-4 rounded-xl shadow-lg mb-4">
            <div className="text-sm font-medium mb-1">当前奖池</div>
            <div className="text-2xl font-bold">
              {poolBalance
                ? `${formatEther(poolBalance.value)} ETH`
                : "加载中..."}
            </div>
          </div>

          {/* 合约部署者充值功能 */}
          {isDeployer && (
            <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-800 mb-3">
                充值奖池
              </h3>
              <div className="flex flex-col sm:flex-row gap-2 items-center justify-center">
                <input
                  type="number"
                  value={fundingAmount}
                  onChange={(e) => setFundingAmount(e.target.value)}
                  placeholder="输入充值金额 (ETH)"
                  className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  step="0.001"
                  min="0"
                />
                <button
                  onClick={handleFundPrizePool}
                  disabled={!fundingAmount || isFunding}
                  className="px-6 py-2 bg-green-600 text-white rounded-lg font-semibold hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {isFunding ? "处理中..." : "充值"}
                </button>
              </div>
            </div>
          )}
        </div>

        <ScratchCard
          contractAddress={CONTRACT_ADDRESS}
          isReady={poolBalance ? poolBalance.value > 0 : false}
        />
      </div>
    </div>
  );
}

// 刮刮乐中奖名单组件
export function ScratchCardWinners() {
  const [currentPage, setCurrentPage] = useState(1);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const itemsPerPage = 5;

  // 刮刮乐中奖数据
  const scratchWinners = [
    { address: "0x1111...2222", prize: "500 USDT", time: "15:20" },
    { address: "0x3333...4444", prize: "100 USDT", time: "14:55" },
    { address: "0x5555...6666", prize: "1000 USDT", time: "14:10" },
    { address: "0x7777...8888", prize: "200 USDT", time: "13:30" },
    { address: "0x9999...aaaa", prize: "800 USDT", time: "12:45" },
    { address: "0xbbbb...cccc", prize: "150 USDT", time: "11:20" },
    { address: "0xdddd...eeee", prize: "600 USDT", time: "10:15" },
    { address: "0xffff...0000", prize: "300 USDT", time: "09:30" },
    { address: "0x1111...3333", prize: "400 USDT", time: "08:45" },
    { address: "0x4444...5555", prize: "120 USDT", time: "07:20" },
    { address: "0x6666...7777", prize: "700 USDT", time: "06:10" },
    { address: "0x8888...9999", prize: "250 USDT", time: "05:25" },
  ];

  // 获取当前页的数据
  const getCurrentPageData = () => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    const endIndex = startIndex + itemsPerPage;
    return scratchWinners.slice(startIndex, endIndex);
  };

  // 计算总页数
  const getTotalPages = () => {
    return Math.ceil(scratchWinners.length / itemsPerPage);
  };

  // 翻页函数
  const goToPreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  const goToNextPage = () => {
    if (currentPage < getTotalPages()) {
      setCurrentPage(currentPage + 1);
    }
  };

  // 刷新函数
  const handleRefresh = async () => {
    setIsRefreshing(true);
    await new Promise((resolve) => setTimeout(resolve, 1000));
    setCurrentPage(1);
    setIsRefreshing(false);
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-xl font-semibold text-gray-800">中奖名单</h3>
        <button
          onClick={handleRefresh}
          disabled={isRefreshing}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          <svg
            className={`w-4 h-4 ${isRefreshing ? "animate-spin" : ""}`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
          <span>{isRefreshing ? "刷新中..." : "刷新"}</span>
        </button>
      </div>

      <div className="space-y-2">
        {getCurrentPageData().map((winner, index) => (
          <div
            key={index}
            className="flex justify-between items-center p-3 bg-gray-50 rounded-lg"
          >
            <span className="text-sm text-gray-600">{winner.address}</span>
            <span className="font-semibold text-blue-600">{winner.prize}</span>
            <span className="text-xs text-gray-500">{winner.time}</span>
          </div>
        ))}
      </div>

      {/* 分页控件 */}
      <div className="flex justify-between items-center mt-6 pt-4 border-t border-gray-200">
        <div className="text-sm text-gray-600">
          第 {currentPage} 页，共 {getTotalPages()} 页
        </div>
        <div className="flex space-x-2">
          <button
            onClick={goToPreviousPage}
            disabled={currentPage === 1}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            上一页
          </button>
          <button
            onClick={goToNextPage}
            disabled={currentPage === getTotalPages()}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            下一页
          </button>
        </div>
      </div>
    </div>
  );
}
