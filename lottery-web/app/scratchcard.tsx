"use client";

import { useEffect, useRef, useState } from "react";

// 刮刮乐刮奖功能组件
export function ScratchCardDraw() {
  // 仅保留单张刮奖
  const [isScratching, setIsScratching] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [results, setResults] = useState<string[]>([]);
  const [isRevealed, setIsRevealed] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const coverRef = useRef<HTMLDivElement | null>(null);
  const isPointerDownRef = useRef(false);
  const moveCounterRef = useRef(0);

  const randomResult = () => {
    const r = Math.random();
    if (r < 0.05) return "大奖";
    if (r < 0.01) return "小奖";
    if (r < 0.05) return "幸运奖";
    return "谢谢惠顾"; // 70%
  };

  const handleScratch = async (count: number) => {
    setIsScratching(true);
    // 模拟刮奖过程
    await new Promise((resolve) => setTimeout(resolve, 500));
    const generated: string[] = Array.from({ length: Math.max(1, count) }, () =>
      randomResult()
    );
    setResults(generated);
    setIsScratching(false);
    setIsModalOpen(true);
    setIsRevealed(false);
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

  const revealIfThreshold = () => {
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
  };

  // 擦除函数
  const eraseAt = (clientX: number, clientY: number) => {
    const canvas = canvasRef.current;
    const container = coverRef.current;
    if (!canvas || !container) return;
    const rect = container.getBoundingClientRect();
    const x = clientX - rect.left;
    const y = clientY - rect.top;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.globalCompositeOperation = "destination-out";
    const brushRadius = Math.max(18, Math.min(rect.width, rect.height) * 0.05);
    const dpr = window.devicePixelRatio || 1;
    ctx.beginPath();
    ctx.arc(x * dpr, y * dpr, brushRadius * dpr, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalCompositeOperation = "source-over";

    // 降频计算：每移动若干次再评估比例
    moveCounterRef.current += 1;
    if (moveCounterRef.current % 10 === 0) revealIfThreshold();
  };

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
  }, [isModalOpen, isRevealed]);

  return (
    <div className="bg-white rounded-lg shadow-lg p-6 min-h-[480px] flex flex-col">
      <h2 className="text-2xl font-bold text-gray-800 mb-6 text-center">
        刮刮乐
      </h2>

      {/* 内容区域 */}
      <div className="space-y-4 flex-1 flex flex-col justify-center">
        <div className="text-center">
          <p className="text-gray-600 mb-4">刮开一张刮刮乐，看看你的运气！</p>
          <button
            onClick={() => handleScratch(1)}
            disabled={isScratching}
            className="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-8 py-3 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            {isScratching ? "刮奖中..." : "刮一张"}
          </button>
        </div>
      </div>

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
