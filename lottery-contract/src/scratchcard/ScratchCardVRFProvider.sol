// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IScratchCardRandProvider, IScratchCardRandCallback} from "./interface/IScratchCardRand.sol";

contract ScratchCardVRFProvider is IScratchCardRandProvider, VRFConsumerBaseV2Plus {
    IScratchCardRandCallback public callback;

    // VRF variables
    bytes32 public keyHash; // VRF key hash
    uint256 public subId; // VRF sub id
    uint32 public callbackGasLimit = 1e7; // VRF callback gas limit
    uint16 public requestConfirmations = 3; // VRF request confirmations

    // key: requestId, value: the address of user
    mapping(uint256 => address) public vrfRequestIds; // VRF request id by user

    error VRFRequestFailed(uint256 requestId);

    constructor(
        address vrfCoordinator,
        uint256 _subId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        keyHash = _keyHash;
        subId = _subId;
    }

    function setCallbackAddress(address _callbackAddress) external onlyOwner {
        callback = IScratchCardRandCallback(_callbackAddress);
    }

    function requestRandomNumbers(address _user) external override {
        uint256 vrfRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        vrfRequestIds[vrfRequestId] = _user;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        address user = vrfRequestIds[_requestId];
        if (user == address(0)) {
            revert VRFRequestFailed(_requestId);
        }

        // get random number and calculate winning number
        uint256 randomNumber = _randomWords[0];

        // call callback function
        callback.callbackFromRand(user, randomNumber);

        delete vrfRequestIds[_requestId];
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
