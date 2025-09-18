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
    uint32 public callbackGasLimit = 1e6; // VRF callback gas limit, require: < 2.5e6
    uint16 public requestConfirmations = 3; // VRF request confirmations, require: [3, 200]
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

    // =========== set function ===========

    function setCallbackAddress(address _callbackAddress) external onlyOwner {
        callback = IDailyLotteryRandCallback(_callbackAddress);
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setSubId(uint256 _subId) external onlyOwner {
        subId = _subId;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }
}
