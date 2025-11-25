import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export", // 静态导出模式
  basePath: "/web3-lottery", // 项目增加路径前缀
  assetPrefix: "/web3-lottery", // 资源文件增加路径前缀

  devIndicators: {
    position: "top-right", // 设置指示器的位置
  },
};

export default nextConfig;
