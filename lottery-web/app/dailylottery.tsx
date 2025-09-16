"use client";

import { useState } from "react";
import { parseEther, parseAbi, decodeEventLog } from "viem";
import { useWriteContract } from "wagmi";
import { waitForTransactionReceipt } from "wagmi/actions";
import { getConfig } from "./wagmi";

const price = parseEther("0.001");
// take numbers abi
const takeNumbersAbi = parseAbi([
  "function takeNumbers(uint64 nums) payable",
  "event TakeNumbersEvent(uint64 indexed lotteryNumber, address indexed user, uint64[] numbers)",
]);

// 天天有奖抽奖功能组件
export function DailyLotteryDraw() {
  const [selectedTab, setSelectedTab] = useState<"single" | "multiple">(
    "single"
  );

  const [ticketCount, setTicketCount] = useState(1);
  const [isDrawing, setIsDrawing] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [numbers, setNumbers] = useState<string[]>([]);

  // the contract address of take numbers
  const takeNumbersContractAddress =
    process.env.NEXT_PUBLIC_CONTRACT_ADDR_DAILYLOTTERY;
  const { writeContractAsync } = useWriteContract();

  const handleDraw = async (count: number) => {
    setIsDrawing(true);

    try {
      if (!takeNumbersContractAddress) {
        throw new Error("未配置合约地址");
      }

      console.log("开始抽奖流程...", {
        contractAddress: takeNumbersContractAddress,
        count,
        price: price.toString(),
        totalValue: (price * BigInt(count)).toString(),
      });

      const totalValue = price * BigInt(count);

      console.log("发送合约交易...");
      const hash = await writeContractAsync({
        abi: takeNumbersAbi,
        address: takeNumbersContractAddress as `0x${string}`,
        functionName: "takeNumbers",
        value: totalValue,
        args: [BigInt(count)],
      });

      console.log("交易已发送，等待确认...", { hash });

      const receipt = await waitForTransactionReceipt(getConfig(), { hash });

      console.log("交易已确认", {
        receipt: receipt,
        status: receipt.status,
        logs: receipt.logs.length,
      });

      let parsed: string[] = [];
      for (const log of receipt.logs) {
        try {
          const decoded = decodeEventLog({
            abi: takeNumbersAbi,
            data: log.data,
            topics: log.topics,
          });

          if (decoded.eventName === "TakeNumbersEvent") {
            const nums = (decoded.args as any).numbers as readonly bigint[];
            parsed = nums.map((n) => n.toString());
            break;
          }
        } catch {
          // 非本事件日志，忽略
        }
      }

      if (parsed.length === 0) {
        throw new Error("交易失败，请稍后重试");
      }

      setNumbers(parsed);
      setIsModalOpen(true);
    } catch (err) {
      console.error("抽奖过程中发生错误:", err);

      let errorMessage = "抽号失败，请稍后重试";

      if (err instanceof Error) {
        if (err.message.includes("timeout")) {
          errorMessage = "交易超时，请检查网络连接或稍后重试";
        } else if (err.message.includes("insufficient funds")) {
          errorMessage = "余额不足，请检查账户余额";
        } else if (err.message.includes("user rejected")) {
          errorMessage = "用户取消了交易";
        } else if (err.message.includes("network")) {
          errorMessage = "网络连接问题，请检查本地节点是否运行";
        } else {
          errorMessage = err.message;
        }
      }

      alert(errorMessage);
    } finally {
      setIsDrawing(false);
    }
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setNumbers([]);
  };

  return (
    <div className="bg-white rounded-lg shadow-lg p-6 min-h-[400px] flex flex-col">
      <h2 className="text-2xl font-bold text-gray-800 mb-6 text-center">
        天天有奖
      </h2>

      {/* 标签页 */}
      <div className="flex space-x-1 mb-6 bg-gray-100 rounded-lg p-1">
        <button
          onClick={() => setSelectedTab("single")}
          className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
            selectedTab === "single"
              ? "bg-blue-500 text-white"
              : "text-gray-600 hover:text-gray-800"
          }`}
        >
          抽一张
        </button>
        <button
          onClick={() => setSelectedTab("multiple")}
          className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
            selectedTab === "multiple"
              ? "bg-blue-500 text-white"
              : "text-gray-600 hover:text-gray-800"
          }`}
        >
          抽多张
        </button>
      </div>

      {/* 内容区域 */}
      <div className="space-y-4 flex-1 flex flex-col justify-center">
        {selectedTab === "single" && (
          <div className="text-center">
            <p className="text-gray-600 mb-4">
              每次抽取一张彩票，中奖概率更高！
            </p>
            <button
              onClick={() => handleDraw(1)}
              disabled={isDrawing}
              className="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-8 py-3 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
            >
              {isDrawing ? "抽奖中..." : "抽一张"}
            </button>
          </div>
        )}

        {selectedTab === "multiple" && (
          <div className="text-center">
            <p className="text-gray-600 mb-4">选择要抽取的彩票数量</p>
            <div className="mb-4">
              <input
                type="number"
                min="1"
                max="10"
                value={ticketCount}
                onChange={(e) => setTicketCount(parseInt(e.target.value) || 1)}
                className="w-20 px-3 py-2 border border-gray-300 rounded-md text-center"
              />
              <span className="ml-2 text-gray-600">张</span>
            </div>
            <button
              onClick={() => handleDraw(ticketCount)}
              disabled={isDrawing}
              className="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-8 py-3 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
            >
              {isDrawing ? "抽奖中..." : `抽取 ${ticketCount} 张`}
            </button>
          </div>
        )}
      </div>

      {/* 结果弹窗 */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={closeModal} />
          <div className="relative z-10 w-[90%] max-w-md bg-white rounded-2xl shadow-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-lg font-semibold text-gray-800">抽奖结果</h4>
              <button
                onClick={closeModal}
                className="text-gray-500 hover:text-gray-700"
                aria-label="关闭"
              >
                ✕
              </button>
            </div>

            {numbers.length === 1 ? (
              <div className="text-center">
                <div className="text-3xl font-bold tracking-widest text-blue-600">
                  {numbers[0]}
                </div>
                <p className="text-gray-600 mt-2">恭喜！您抽到的号码如下</p>
              </div>
            ) : (
              <div>
                <p className="text-sm text-gray-500 mb-2">
                  共抽取 {numbers.length} 张：
                </p>
                <div className="grid grid-cols-2 gap-2">
                  {numbers.map((n, i) => (
                    <div
                      key={i}
                      className="p-3 rounded-lg border border-gray-200 text-center"
                    >
                      <span className="font-mono tracking-widest text-blue-700 font-semibold">
                        {n}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="mt-6 flex justify-end">
              <button
                onClick={closeModal}
                className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700"
              >
                知道了
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// 天天有奖中奖名单组件
export function DailyLotteryWinners() {
  const [currentPage, setCurrentPage] = useState(1);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const itemsPerPage = 5;

  // 天天有奖中奖数据
  const dailyWinners = [
    { address: "0x1234...5678", prize: "100 USDT", time: "14:30" },
    { address: "0xabcd...efgh", prize: "50 USDT", time: "13:45" },
    { address: "0x9876...4321", prize: "200 USDT", time: "12:20" },
    { address: "0x1111...2222", prize: "150 USDT", time: "11:15" },
    { address: "0x3333...4444", prize: "75 USDT", time: "10:30" },
    { address: "0x5555...6666", prize: "300 USDT", time: "09:45" },
    { address: "0x7777...8888", prize: "80 USDT", time: "08:20" },
    { address: "0x9999...aaaa", prize: "120 USDT", time: "07:10" },
    { address: "0xbbbb...cccc", prize: "90 USDT", time: "06:30" },
    { address: "0xdddd...eeee", prize: "250 USDT", time: "05:45" },
    { address: "0xffff...0000", prize: "60 USDT", time: "04:20" },
    { address: "0x1111...3333", prize: "180 USDT", time: "03:15" },
  ];

  // 获取当前页的数据
  const getCurrentPageData = () => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    const endIndex = startIndex + itemsPerPage;
    return dailyWinners.slice(startIndex, endIndex);
  };

  // 计算总页数
  const getTotalPages = () => {
    return Math.ceil(dailyWinners.length / itemsPerPage);
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
            <span className="font-semibold text-green-600">{winner.prize}</span>
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
