// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, stdJson} from "forge-std/Script.sol";
import "forge-std/console.sol";

abstract contract BaseDeploy is Script {
    using stdJson for string;

    function getDeploymentFilePath(string memory filename) internal view returns (string memory) {
        uint256 chainId = block.chainid;
        string memory networkName = getNetworkName(chainId);
        return string.concat("deployments/", networkName, "/", filename, ".json");
    }

    function getNetworkName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "mainnet";
        if (chainId == 11155111) return "sepolia";
        if (chainId == 31337) return "anvil";
        if (chainId == 5) return "goerli";
        if (chainId == 137) return "polygon";
        if (chainId == 80001) return "mumbai";
        if (chainId == 42161) return "arbitrum";
        if (chainId == 421613) return "arbitrum-sepolia";
        if (chainId == 10) return "optimism";
        if (chainId == 420) return "optimism-sepolia";
        if (chainId == 43114) return "avalanche";
        if (chainId == 43113) return "avalanche-fuji";
        // 默认使用 chainId 作为文件夹名
        return vm.toString(chainId);
    }

    function readAddress(string memory path, string memory key) internal view returns (address) {
        string memory json = vm.readFile(path);
        return json.readAddress(string.concat(".", key));
    }

    function writeJson(string memory path, string memory key, address addr) internal {
        string memory objKey = "root";

        // 1. 读现有文件
        string memory existingJson = vm.readFile(path);

        string memory jsonToWrite;
        if (bytes(existingJson).length == 0) {
            // 文件为空：直接新建
            jsonToWrite = vm.serializeAddress(objKey, key, addr);
        } else {
            // 2. 把现有 JSON 作为字符串注入内存对象（serializeJson 特殊：它序列化整个字符串）
            vm.serializeJson(objKey, existingJson); // 注入旧 JSON 到根

            // 3. 在注入后追加新 key（内存现在有旧+新）
            jsonToWrite = vm.serializeAddress(objKey, key, addr);
        }

        // 4. 最后一次性写回文件
        vm.writeJson(jsonToWrite, path);
    }
}
