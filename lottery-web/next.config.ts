import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export", // 静态导出模式

  devIndicators: {
    position: "top-right", // 设置指示器的位置
  },
};

export default nextConfig;
