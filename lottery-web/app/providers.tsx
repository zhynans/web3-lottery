"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { type ReactNode, useState } from "react";
import { type State, WagmiProvider } from "wagmi";
import { getConfig } from "@/app/wagmi";

import "@rainbow-me/rainbowkit/styles.css";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";

export function Providers(props: {
  children: ReactNode;
  initialState?: State;
}) {
  // 这里使用 useState 是为了确保 getConfig() 和 new QueryClient() 只在组件首次渲染时执行一次，
  // 并且在组件的整个生命周期内保持同一个实例，避免每次渲染都重新创建对象，导致状态丢失或副作用。
  const [config] = useState(() => getConfig());
  const [queryClient] = useState(() => new QueryClient());

  return (
    <WagmiProvider config={config} initialState={props.initialState}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider showRecentTransactions={false}>
          {props.children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
