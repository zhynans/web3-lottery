import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  devIndicators: {
    position: "top-right", // 设置指示器的位置
    buildActivity: false,
  },
};

export default nextConfig;
