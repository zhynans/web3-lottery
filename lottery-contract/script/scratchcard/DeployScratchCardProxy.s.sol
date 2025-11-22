// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./Constants.sol";
import {BaseScratchCardDeploy} from "./BaseScratchCardDeploy.s.sol";
import {ScratchCardV1} from "src/scratchcard/ScratchCardV1.sol";
import {ScratchCardVRFProvider} from "src/scratchcard/ScratchCardVRFProvider.sol";
import {IScratchCardToken} from "src/scratchcard/interface/IScratchCardToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScratchCardProxy is BaseScratchCardDeploy {
    function run() public returns (address proxyAddress) {
        // env variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");
        string memory deploymentFile = getDeploymentFilePath();

        // read deployment addresses from JSON
        address zeroAddr = address(0);
        address resultAddress = readAddress(deploymentFile, DEPLOY_RESULT_ADDR);
        require(resultAddress != zeroAddr, "The result address cannot be zero");
        address tokenAddress = readAddress(deploymentFile, DEPLOY_TOKEN_ADDR);
        require(tokenAddress != zeroAddr, "The token address cannot be zero");
        address vrfProviderAddress = readAddress(deploymentFile, DEPLOY_RAND_PROVIDER_ADDR);
        require(vrfProviderAddress != zeroAddr, "The vrfProvider address cannot be zero");
        address configAddress = readAddress(deploymentFile, DEPLOY_CONFIG_ADDR);
        require(configAddress != zeroAddr, "The config Address cannot be zero");
        address implementationAddress = readAddress(deploymentFile, DEPLOY_IMPL_V1_ADDR);
        require(implementationAddress != zeroAddr, "The impl Address cannot be zero");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(
            ScratchCardV1.initialize.selector,
            resultAddress,
            tokenAddress,
            vrfProviderAddress,
            configAddress
        );
        ERC1967Proxy proxy = new ERC1967Proxy(implementationAddress, initData);
        proxyAddress = address(proxy);

        // set callback address
        ScratchCardVRFProvider(vrfProviderAddress).setCallbackAddress(proxyAddress);

        // set allowed minter
        IScratchCardToken(tokenAddress).setAllowedMinter(proxyAddress);

        // stop broadcast
        vm.stopBroadcast();

        // save deployment address to JSON
        writeJson(deploymentFile, DEPLOY_PROXY_ADDR, proxyAddress);

        return proxyAddress;
    }
}
