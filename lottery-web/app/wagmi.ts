import { cookieStorage, createConfig, createStorage, http } from "wagmi";

import { mainnet, sepolia } from "wagmi/chains";
import { baseAccount, injected } from "wagmi/connectors";

const localChain = {
  id: 31337,
  name: "Localhost",
  network: "localhost",
  nativeCurrency: { name: "Local", symbol: "LOC", decimals: 18 },
  rpcUrls: {
    default: { http: ["http://localhost:8545"] },
  },
  blockExplorers: { default: { name: "None", url: "" } },
  testnet: true,
};

// wagmi config
export const getConfig = () => {
  return createConfig({
    chains: [mainnet, sepolia, localChain],
    connectors: [injected(), baseAccount()],
    storage: createStorage({
      storage: cookieStorage,
    }),
    ssr: true,
    transports: {
      [mainnet.id]: http(),
      [sepolia.id]: http(),
    },
  });
};

declare module "wagmi" {
  interface Register {
    config: typeof getConfig;
  }
}
