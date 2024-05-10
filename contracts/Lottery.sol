// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

error Lottery_Error_EntranceFee();

error Lottery__TransferFailed();

contract Lottery is VRFConsumerBaseV2Plus {
    /**Event */
    //抽奖人事件
    event lotteryEnter(address indexed player);

    //VRF发送事件
    event RequestedLotteryWinner(uint256 indexed requestId);

    //获得抽奖人事件
    event WinnerPicked(address indexed winner);

    /**state Variables */
    //入场费
    uint256 private immutable s_i_entranceFee;

    //记录抽奖人
    address payable[] private s_players;

    //VRF
    //i_subscriptionId
    uint256 private immutable i_subscriptionId;

    //gasLimit
    uint32 private immutable i_callbackGasLimit;

    //keyHash
    bytes32 private immutable i_keyHash;

    //COORDINATOR
    IVRFCoordinatorV2Plus private immutable i_coordinator; //0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B

    // The default is 3, but you can set this higher.
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 private constant NUM_WORDS = 2;

    //获取抽奖人
    address payable private recentWinner;

    constructor(
        uint256 _entranceFee,
        uint256 _subscriptionId,
        address _coordinator,
        uint32 _callbackGasLimit,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_coordinator) {
        s_i_entranceFee = _entranceFee;
        i_coordinator = IVRFCoordinatorV2Plus(_coordinator);
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_keyHash = _keyHash;
    }

    //发起抽奖
    function enterLottery() public payable {
        if (msg.value < s_i_entranceFee) {
            revert Lottery_Error_EntranceFee();
        }
        s_players.push(payable(msg.sender));
        emit lotteryEnter(msg.sender);
    }

    //抽取随机获奖者
    function pickRandomWinner() public {}

    //查看入场费
    function getEntranceFee() public view returns (uint256) {
        return s_i_entranceFee;
    }

    //获取抽奖人
    function getPlayers(uint16 _index) public view returns (address) {
        return s_players[_index];
    }

    //发送VRF
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        // To enable payment in native tokens, set nativePayment to true.
        uint256 requestId = i_coordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedLotteryWinner(requestId);
    }

    //通过VRF合约获取随机数
    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        recentWinner = s_players[indexOfWinner];
        s_players = new address payable[](0);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    function getRecentWinner() public view returns (address payable) {
        return recentWinner;
    }
}
