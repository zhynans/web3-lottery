"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useState } from "react";
import { DailyLotteryDraw, DailyLotteryWinners } from "@/app/dailylottery";
import { ScratchCardDraw, ScratchCardWinners } from "@/app/scratchcard";

export default function Home() {
  const [activeMenu, setActiveMenu] = useState<"daily" | "scratch">("daily");

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-purple-50">
      {/* 顶部导航栏 */}
      <div className="bg-white shadow-lg relative">
        <div className="max-w-6xl mx-auto px-4 py-4 ">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold text-gray-800">
              去中心化彩票系统
            </h1>
            <div></div>
          </div>
        </div>
        <div className="absolute right-12 top-1/2 -translate-y-1/2">
          <ConnectButton />
        </div>
      </div>

      {/* 主内容区域 */}
      <div className="max-w-6xl mx-auto px-4 py-8">
        {/* 菜单导航 */}
        <div className="flex justify-center mb-8">
          <div className="bg-white rounded-lg shadow-lg p-1">
            <button
              onClick={() => setActiveMenu("daily")}
              className={`px-8 py-3 rounded-md font-semibold transition-all ${
                activeMenu === "daily"
                  ? "bg-blue-500 text-white shadow-lg"
                  : "text-gray-600 hover:text-gray-800 hover:bg-gray-100"
              }`}
            >
              天天有奖
            </button>
            <button
              onClick={() => setActiveMenu("scratch")}
              className={`px-8 py-3 rounded-md font-semibold transition-all ${
                activeMenu === "scratch"
                  ? "bg-blue-500 text-white shadow-lg"
                  : "text-gray-600 hover:text-gray-800 hover:bg-gray-100"
              }`}
            >
              刮刮乐
            </button>
          </div>
        </div>

        {/* 功能模块 */}
        <div className="max-w-4xl mx-auto space-y-6">
          {activeMenu === "daily" && (
            <>
              <DailyLotteryDraw />
              <DailyLotteryWinners />
            </>
          )}
          {activeMenu === "scratch" && (
            <>
              <ScratchCardDraw />
              <ScratchCardWinners />
            </>
          )}
        </div>
      </div>
    </div>
  );
}
