// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IDailyLotteryRandProvider} from "./interface/IDailyLotteryRand.sol";
import {IDailyLotteryRandCallback} from "./interface/IDailyLotteryRand.sol";

contract DailyLotteryVRFProvider is IDailyLotteryRandProvider, VRFConsumerBaseV2Plus {
    IDailyLotteryRandCallback public callback;

    // VRF variables
    bytes32 public keyHash; // VRF key hash
    uint256 public subId; // VRF sub id
    uint32 public callbackGasLimit = 1e7; // VRF callback gas limit
    uint16 public requestConfirmations = 3; // VRF request confirmations
    uint256 public vrfRequestId; // VRF request id

    error VRFRequestFailed();
    error VRFRequestAlreadyRequested();

    constructor(
        address vrfCoordinator,
        uint256 _subId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        keyHash = _keyHash;
        subId = _subId;
    }

    function setCallbackAddress(address _callbackAddress) external onlyOwner {
        callback = IDailyLotteryRandCallback(_callbackAddress);
    }

    function requestRandomNumbers(uint32 nums) external override {
        if (vrfRequestId != 0) {
            revert VRFRequestAlreadyRequested();
        }

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
        callback.callbackFromRand(randomNumber);

        vrfRequestId = 0;
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
