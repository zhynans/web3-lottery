import { cookieStorage, createConfig, createStorage, http } from "wagmi";

import { injected } from "wagmi/connectors";
import { sepolia } from "wagmi/chains";

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
  const transports: Record<number, any> = {
    // [mainnet.id]: http(),
    [sepolia.id]: http(
      "https://eth-sepolia.g.alchemy.com/v2/y8Q8CNRbC_f36_VtVTY1a"
    ),
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
