import {
  cookieStorage,
  createConfig,
  createStorage,
  http,
  webSocket,
} from "wagmi";
import { fallback } from "viem";
import type { Transport } from "viem";

import { injected } from "wagmi/connectors";
import { sepolia } from "wagmi/chains";

// 获取Infra Sepolia的HTTP和WebSocket地址
const getSepoliaInfraUrls = () => {
  const sepoliaInfraHttpUrl = process.env.NEXT_PUBLIC_SEPOLIA_INFURA_HTTP_URL;
  if (!sepoliaInfraHttpUrl) {
    throw new Error("NEXT_PUBLIC_SEPOLIA_INFURA_HTTP_URL is not set");
  }
  const sepoliaInfraWsUrl = process.env.NEXT_PUBLIC_SEPOLIA_INFURA_WSS_URL;
  if (!sepoliaInfraWsUrl) {
    throw new Error("NEXT_PUBLIC_SEPOLIA_INFURA_WSS_URL is not set");
  }

  return [sepoliaInfraHttpUrl, sepoliaInfraWsUrl];
};

// local chain config
const createLocalChain = () => {
  return {
    id: 31337,
    name: "Localhost",
    network: "localhost",
    nativeCurrency: {
      name: "Local",
      symbol: "LOC",
      decimals: 18,
    },
    rpcUrls: {
      default: { http: ["http://localhost:8545"] },
      public: { http: ["http://localhost:8545"] },
    },
    blockExplorers: {
      default: {
        name: "None",
        url: "",
      },
    },
    testnet: true,
    blockTime: 12000,
    contracts: {},
  } as const;
};

export const getSupportChains = () => {
  const appEnv = process.env.NEXT_PUBLIC_APP_ENV || "development";
  const chains = [sepolia] as const;

  // development
  if (appEnv === "development") {
    const localChain = createLocalChain();
    return [localChain, ...chains] as const;
  }

  return chains;
};

// 动态创建传输配置
const createTransports = () => {
  // Infura Sepolia HTTP and WebSocket URLs
  const [sepoliaInfraHttpUrl, sepoliaInfraWsUrl] = getSepoliaInfraUrls();

  const transports: Record<number, Transport> = {
    // [mainnet.id]: http(),
    [sepolia.id]: fallback([
      webSocket(sepoliaInfraWsUrl, {
        retryCount: 10,
        retryDelay: 1_000, // 1s 重连间隔
      }),
      http(sepoliaInfraHttpUrl, {
        // 轮询降级的重试/超时
        retryCount: 3,
        timeout: 6_000,
      }),
    ]),
  };

  // development
  const appEnv = process.env.NEXT_PUBLIC_APP_ENV || "development";
  if (appEnv === "development") {
    const localChain = createLocalChain();
    transports[localChain.id] = http("http://localhost:8545");
  }

  return transports;
};

// wagmi config
export const getConfig = () => {
  return createConfig({
    chains: getSupportChains(),
    connectors: [injected()],
    storage: createStorage({
      storage: cookieStorage,
    }),
    ssr: false,
    transports: createTransports(),
  });
};

declare module "wagmi" {
  interface Register {
    config: typeof getConfig;
  }
}
