// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IDailyLotteryRandProvider} from "./IDailyLotteryRandProvider.sol";
import {DailyLottery} from "../DailyLottery.sol";

contract IDailyLotteryVRFProvider is IDailyLotteryRandProvider, VRFConsumerBaseV2Plus {
    DailyLottery public dailyLottery;

    // VRF variables
    bytes32 public keyHash; // VRF key hash
    uint256 public subId; // VRF sub id
    uint32 public callbackGasLimit = 100000; // VRF callback gas limit
    uint16 public requestConfirmations = 3; // VRF request confirmations
    uint256 public vrfRequestId; // VRF request id

    error VRFRequestFailed();

    constructor(
        address vrfCoordinator,
        uint256 _subId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        keyHash = _keyHash;
        subId = _subId;
    }

    function updateCallbackAddress(address _callbackAddress) external onlyOwner {
        dailyLottery = DailyLottery(_callbackAddress);
    }

    function requestRandomNumbers(uint32 nums) external override {
        // request VRF random number
        vrfRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: nums,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        if (_requestId != vrfRequestId) {
            revert VRFRequestFailed();
        }

        // get random number and calculate winning number
        uint256 randomNumber = _randomWords[0];

        // call callback function
        dailyLottery.callbackFromRandomManager(randomNumber);
    }

    // set VRF parameters (only owner can call)
    function setVrfParameters(
        uint64 _subId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) public onlyOwner {
        if (_subId != 0) {
            subId = _subId;
        }
        if (_keyHash != 0) {
            keyHash = _keyHash;
        }
        if (_callbackGasLimit != 0) {
            callbackGasLimit = _callbackGasLimit;
        }
        if (_requestConfirmations != 0) {
            requestConfirmations = _requestConfirmations;
        }
    }
}
