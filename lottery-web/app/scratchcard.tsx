"use client";

import { useState, useEffect } from "react";
import { waitForTransactionReceipt } from "wagmi/actions";
import { useBalance, useAccount, useWriteContract } from "wagmi";
import { parseEther, formatEther, parseAbi, decodeEventLog } from "viem";
import { getConfig } from "./wagmi";
import { ScratchCard } from "./components/ScratchCard";
import toast from "react-hot-toast";
import { scratchCardAbi } from "./lib/abi";
import { getLotteryResultList, LotteryResult } from "./graph/scratchcard";

// 合约地址和ABI（这里需要根据实际合约地址和ABI进行配置）
const CONTRACT_ADDRESS = process.env
  .NEXT_PUBLIC_CONTRACT_ADDR_SCRATCHCARD as `0x${string}`;
const CONTRACT_DEPLOYER = process.env
  .NEXT_PUBLIC_CONTRACT_DEPLOYER as `0x${string}`;

const prizeMap: Record<number, string> = {
  0: "未中奖",
  1: "大奖",
  2: "小奖",
  3: "幸运奖",
};

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
        abi: scratchCardAbi,
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

  const [scratchResults, setScratchResults] = useState<Array<LotteryResult>>(
    []
  );

  // get winners from graph
  const fetchWinners = async (currentPage: number, pageSize: number) => {
    const data = await getLotteryResultList(currentPage, pageSize);
    setScratchResults(data);
  };

  useEffect(() => {
    fetchWinners(currentPage, itemsPerPage);
  }, [currentPage, itemsPerPage]);

  // 是否还有下一页（当返回条数等于分页大小时，可能还有下一页）
  const hasNextPage = scratchResults.length === itemsPerPage;

  // 翻页函数
  const goToPreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  const goToNextPage = () => {
    if (hasNextPage) {
      setCurrentPage(currentPage + 1);
    }
  };

  // 刷新函数
  const handleRefresh = async () => {
    setIsRefreshing(true);

    fetchWinners(1, itemsPerPage).finally(() => {
      setIsRefreshing(false);
    });
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-xl font-semibold text-gray-800">抽奖记录</h3>
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
        {scratchResults.map((item, index) => {
          // 地址格式化为 0x开头，前2位+...+后4位
          const formatAddress = (address: string) => {
            if (!address) return "";
            return `${address.slice(0, 6)}...${address.slice(-6)}`;
          };

          const formatTimestamp = (timestamp: number) => {
            const date = new Date(timestamp * 1000);
            const pad = (n: number) => n.toString().padStart(2, "0");
            const year = date.getFullYear();
            const month = pad(date.getMonth() + 1);
            const day = pad(date.getDate());
            const hour = pad(date.getHours());
            const minute = pad(date.getMinutes());
            const second = pad(date.getSeconds());
            return `${year}-${month}-${day} ${hour}:${minute}:${second}`;
          };

          return (
            <div
              key={index}
              className="flex justify-between items-center p-3 bg-gray-50 rounded-lg"
            >
              <span className="text-sm text-gray-800">
                用户（{formatAddress(item.user)}）
              </span>
              <span className="font-semibold text-blue-600">
                {prizeMap[item.prize]}
              </span>
              {item.amount > 0 && (
                <span className="text-green-600 font-semibold ml-2">
                  金额：{item.amount}
                </span>
              )}
              <span className="text-xs text-gray-500">
                {formatTimestamp(item.timestamp)}
              </span>
            </div>
          );
        })}
      </div>

      {/* 分页控件 */}
      <div className="flex justify-end items-center mt-6 pt-4 border-t border-gray-200">
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
            disabled={!hasNextPage}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            下一页
          </button>
        </div>
      </div>
    </div>
  );
}
