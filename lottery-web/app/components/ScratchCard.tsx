"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { waitForTransactionReceipt } from "wagmi/actions";
import { useAccount, useWriteContract, useWatchContractEvent } from "wagmi";
import { parseEther, formatEther } from "viem";
import { getConfig } from "../wagmi";
import toast from "react-hot-toast";
import { scratchCardAbi } from "../lib/abi";

const price = parseEther("0.001");
const thanksLogs = {
  prize: 0,
  amount: 0,
};

interface ScratchCardProps {
  contractAddress: `0x${string}`;
  isReady: boolean;
}

export function ScratchCard({ contractAddress, isReady }: ScratchCardProps) {
  const [isScratching, setIsScratching] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [results, setResults] = useState<string[]>([]);
  const [isRevealed, setIsRevealed] = useState(false);
  const [eventListenerEnabled, setEventListenerEnabled] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const coverRef = useRef<HTMLDivElement | null>(null);
  const isPointerDownRef = useRef(false);
  const moveCounterRef = useRef(0);

  const { writeContractAsync } = useWriteContract();

  const { address, isConnected } = useAccount();

  // 监听 LotteryResultEvent 事件
  useWatchContractEvent({
    address: contractAddress,
    abi: scratchCardAbi,
    eventName: "LotteryResultEvent",
    args: {
      user: address, // 只监听当前用户的事件
    },
    poll: true,
    pollingInterval: 1000,
    enabled:
      isConnected && !!address && !!contractAddress && eventListenerEnabled, // 只在需要时启用
    onLogs: (logs) => {
      console.log("收到 LotteryResult 事件:", logs);
      if (logs.length > 0) {
        const log = logs[0] as any;
        const args = (log && (log as any).args) || log;
        handleLotteryResult(args);
      }
    },
    onError: (error) => {
      console.error("监听事件时出错:", error);
      // 只在刮奖过程中显示错误，避免干扰用户
      if (isScratching) {
        handleLotteryResult(thanksLogs);
      }
    },
  });

  // 处理彩票结果
  const handleLotteryResult = useCallback((args: any) => {
    const prize = Number(args.prize);
    const prizeAmount = Number(formatEther(args.amount));
    let prizeResult = "谢谢惠顾";
    let amount = 0;

    // 根据枚举值确定奖品类型
    switch (prize) {
      case 0: // NoPrize
        prizeResult = "谢谢惠顾";
        break;
      case 1: // GrandPrize
        prizeResult = "大奖";
        amount = prizeAmount;
        break;
      case 2: // SmallPrize
        prizeResult = "小奖";
        amount = prizeAmount;
        break;
      case 3: // LuckyPrize
        prizeResult = "幸运奖";
        amount = prizeAmount;
        break;
      default:
        prizeResult = "谢谢惠顾";
    }

    setResults([prizeResult]);
    setIsScratching(false);
    setIsModalOpen(true);
    setIsRevealed(false);
    setEventListenerEnabled(false);
  }, []);

  // 刮奖处理函数
  const handleScratch = async () => {
    if (!contractAddress) return;

    if (!isConnected) {
      toast.error("请连接钱包");
      return;
    }
    if (!address) {
      toast.error("无法获取账户或网络，请重试");
      return;
    }

    try {
      setIsScratching(true);
      setEventListenerEnabled(true); // 启用事件监听

      const hash = await writeContractAsync({
        abi: scratchCardAbi,
        address: contractAddress,
        functionName: "scratchCard",
        value: price,
      });

      // 等待交易确认
      const repcepit = await waitForTransactionReceipt(getConfig(), { hash });
      if (repcepit.status !== "success") {
        toast.error("操作未成功，请稍后重试");
        setIsScratching(false);
        setEventListenerEnabled(false);
        return;
      }
      console.log("刮奖交易已提交，等待 VRF 回调...");
    } catch (error) {
      toast.error("刮奖失败");
      console.error("刮奖失败", error);
      setIsScratching(false);
      setEventListenerEnabled(false);
    }
  };

  // 初始化/重绘遮罩
  const paintMask = () => {
    const canvas = canvasRef.current;
    const container = coverRef.current;
    if (!canvas || !container) return;

    const rect = container.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    canvas.width = Math.floor(rect.width * dpr);
    canvas.height = Math.floor(rect.height * dpr);
    canvas.style.width = `${rect.width}px`;
    canvas.style.height = `${rect.height}px`;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.scale(dpr, dpr);
    const radius = 12;
    const w = rect.width;
    const h = rect.height;
    ctx.clearRect(0, 0, w, h);

    // 绘制银灰遮罩带胶粒效果
    const gradient = ctx.createLinearGradient(0, 0, w, h);
    gradient.addColorStop(0, "#c0c0c0");
    gradient.addColorStop(1, "#9e9e9e");
    ctx.fillStyle = gradient;

    // 圆角矩形
    ctx.beginPath();
    ctx.moveTo(radius, 0);
    ctx.lineTo(w - radius, 0);
    ctx.quadraticCurveTo(w, 0, w, radius);
    ctx.lineTo(w, h - radius);
    ctx.quadraticCurveTo(w, h, w - radius, h);
    ctx.lineTo(radius, h);
    ctx.quadraticCurveTo(0, h, 0, h - radius);
    ctx.lineTo(0, radius);
    ctx.quadraticCurveTo(0, 0, radius, 0);
    ctx.closePath();
    ctx.fill();

    // 颗粒点
    ctx.globalAlpha = 0.15;
    ctx.fillStyle = "#ffffff";
    for (let i = 0; i < 150; i++) {
      const x = Math.random() * w;
      const y = Math.random() * h;
      const r = Math.random() * 2 + 0.5;
      ctx.beginPath();
      ctx.arc(x, y, r, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  };

  // 关闭弹窗并重置
  const closeModal = () => {
    setIsModalOpen(false);
    setTimeout(() => {
      setIsRevealed(false);
      const ctx = canvasRef.current?.getContext("2d");
      if (ctx) {
        ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
      }
    }, 200);
  };

  // 计算已擦除比例
  const calculateErasedRatio = (): number => {
    const canvas = canvasRef.current;
    if (!canvas) return 0;
    const ctx = canvas.getContext("2d");
    if (!ctx) return 0;
    const { width, height } = canvas;
    const imageData = ctx.getImageData(0, 0, width, height);
    const data = imageData.data;
    let cleared = 0;
    for (let i = 3; i < data.length; i += 4) {
      if (data[i] === 0) cleared++;
    }
    return cleared / (width * height);
  };

  const revealIfThreshold = useCallback(() => {
    const ratio = calculateErasedRatio();
    if (ratio >= 0.5 && !isRevealed) {
      // 直接清空剩余遮罩
      const canvas = canvasRef.current;
      const ctx = canvas?.getContext("2d");
      if (ctx && canvas) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
      setIsRevealed(true);
    }
  }, [isRevealed]);

  // 擦除函数
  const eraseAt = useCallback(
    (clientX: number, clientY: number) => {
      const canvas = canvasRef.current;
      const container = coverRef.current;
      if (!canvas || !container) return;
      const rect = container.getBoundingClientRect();
      const x = clientX - rect.left;
      const y = clientY - rect.top;
      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      ctx.globalCompositeOperation = "destination-out";
      const brushRadius = Math.max(
        18,
        Math.min(rect.width, rect.height) * 0.05
      );
      const dpr = window.devicePixelRatio || 1;
      ctx.beginPath();
      ctx.arc(x * dpr, y * dpr, brushRadius * dpr, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalCompositeOperation = "source-over";

      // 降频计算：每移动若干次再评估比例
      moveCounterRef.current += 1;
      if (moveCounterRef.current % 10 === 0) {
        const ratio = calculateErasedRatio();
        if (ratio >= 0.5 && !isRevealed) {
          // 直接清空剩余遮罩
          const canvas = canvasRef.current;
          const ctx = canvas?.getContext("2d");
          if (ctx && canvas) {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
          }
          setIsRevealed(true);
        }
      }
    },
    [isRevealed]
  );

  // 绑定指针事件
  useEffect(() => {
    if (!isModalOpen) return;
    paintMask();
    const canvas = canvasRef.current;
    const container = coverRef.current;
    if (!canvas || !container) return;

    const onPointerDown = (e: PointerEvent) => {
      isPointerDownRef.current = true;
      eraseAt(e.clientX, e.clientY);
    };
    const onPointerMove = (e: PointerEvent) => {
      if (!isPointerDownRef.current || isRevealed) return;
      eraseAt(e.clientX, e.clientY);
    };
    const onPointerUp = () => {
      if (!isPointerDownRef.current) return;
      isPointerDownRef.current = false;
      revealIfThreshold();
    };

    container.addEventListener("pointerdown", onPointerDown);
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", onPointerUp);

    // 处理尺寸变化
    const ro = new ResizeObserver(() => {
      if (!isRevealed) paintMask();
    });
    ro.observe(container);

    return () => {
      container.removeEventListener("pointerdown", onPointerDown);
      window.removeEventListener("pointermove", onPointerMove);
      window.removeEventListener("pointerup", onPointerUp);
      ro.disconnect();
    };
  }, [isModalOpen, isRevealed, eraseAt]);

  return (
    <>
      {/* 刮奖按钮 */}
      {isReady && (
        <div className="text-center">
          <p className="text-gray-600 mb-4">刮开一张刮刮乐，看看你的运气！</p>
          <button
            onClick={handleScratch}
            disabled={isScratching}
            className="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-8 py-3 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            {isScratching ? "刮奖中..." : "刮一张"}
          </button>
        </div>
      )}

      {/* 结果弹窗 */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={closeModal} />
          <div className="relative z-10 w-[90%] max-w-md bg-white rounded-2xl shadow-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-lg font-semibold text-gray-800">
                刮刮乐结果
              </h4>
              <button
                onClick={closeModal}
                className="text-gray-500 hover:text-gray-700"
                aria-label="关闭"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3 relative" ref={coverRef}>
              {results.length === 1 ? (
                <div className="text-center">
                  <div className="text-3xl font-bold mb-2 bg-clip-text text-transparent bg-gradient-to-r from-yellow-400 to-red-500">
                    {results[0]}
                  </div>
                  <p className="text-gray-600">恭喜你获得「{results[0]}」！</p>
                </div>
              ) : (
                <div>
                  <p className="text-sm text-gray-500 mb-2">
                    共刮开 {results.length} 张：
                  </p>
                  <div className="grid grid-cols-2 gap-2">
                    {results.map((r, i) => (
                      <div
                        key={i}
                        className="p-3 rounded-lg border border-gray-200 text-center"
                      >
                        <span className="font-semibold">{r}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {!isRevealed && (
                <canvas
                  ref={canvasRef}
                  className="absolute inset-0 rounded-xl touch-none cursor-pointer"
                />
              )}
            </div>

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
    </>
  );
}
