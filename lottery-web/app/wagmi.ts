import { cookieStorage, createConfig, createStorage, http } from "wagmi";

import { mainnet, sepolia } from "wagmi/chains";
import { baseAccount, injected } from "wagmi/connectors";

// wagmi config
export const getConfig = () => {
  return createConfig({
    chains: [mainnet, sepolia],
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
