// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

error Lottery_Error_EntranceFee();

error Lottery__Error_TransferFailed();

error Lottery_Error_StateNotOpen();

error Lottery_Error_UpkeepNotNeeded(uint currBalance, uint playerCount, uint lotteryState);

/**
 * @title Lottery
 * @notice 这是一个抽奖合约，使用VRF来生成随机数，并使用Automation来触发抽奖
 * @dev 这是一个抽奖合约，使用VRF来生成随机数，并使用Automation来触发抽奖
 * @author Andorra
 */

contract Lottery is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /**Event */
    //抽奖人事件
    event lotteryEnter(address indexed player);

    //VRF发送事件
    event RequestedLotteryWinner(uint256 indexed requestId);

    //获得抽奖人事件
    event WinnerPicked(address indexed winner);

    //enum  0-> open; 1-> calculating
    enum lotteryState {
        OPEN,
        CALCULATING
    }

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

    //抽奖的状态
    lotteryState private s_lotteryState;

    //获取抽奖人
    address payable private recentWinner;

    //更新的时间间隔
    uint private s_interval;
    //当前最新的区块时间戳
    uint private s_lastTimeStamp;

    constructor(
        uint256 _entranceFee,
        uint256 _subscriptionId,
        address _coordinator,
        uint32 _callbackGasLimit,
        bytes32 _keyHash,
        uint _interval
    ) VRFConsumerBaseV2Plus(_coordinator) {
        s_i_entranceFee = _entranceFee;
        i_coordinator = IVRFCoordinatorV2Plus(_coordinator);
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_keyHash = _keyHash;
        s_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        s_lotteryState = lotteryState.OPEN;
    }

    //发起抽奖
    function enterLottery() public payable {
        if (msg.value < s_i_entranceFee) {
            revert Lottery_Error_EntranceFee();
        }
        if (s_lotteryState != lotteryState.OPEN) {
            revert Lottery_Error_StateNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit lotteryEnter(msg.sender);
    }

    //检测自动更新
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        // upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.

        bool isOpen = (s_lotteryState == lotteryState.OPEN); //状态是否开启
        bool isTimeout = (block.timestamp - s_lastTimeStamp) > s_interval; // 时间是否个大于更新时间
        bool hasPlayer = (s_players.length > 0); //是否有玩家
        bool hasBalance = (address(this).balance > 0); // 是否有余额
        upkeepNeeded = bool(isOpen && isTimeout && hasBalance && hasPlayer);
    }

    //发送VRF
    function performUpkeep(bytes calldata /* performData */) external override {
        // Will revert if subscription is not set and funded.
        // To enable payment in native tokens, set nativePayment to true.
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery_Error_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint(s_lotteryState)
            );
        }

        s_lotteryState = lotteryState.CALCULATING;
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
        s_lotteryState = lotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__Error_TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    function getRecentWinner() public view returns (address payable) {
        return recentWinner;
    }

    //查看入场费
    function getEntranceFee() public view returns (uint256) {
        return s_i_entranceFee;
    }

    //获取抽奖人
    function getPlayers(uint16 _index) public view returns (address) {
        return s_players[_index];
    }

    //获取最后一次时间
    function getLasttimestamp() public view returns (uint) {
        return s_lastTimeStamp;
    }

    //获取当前状态
    function getLottertState() public view returns (lotteryState) {
        return s_lotteryState;
    }

    //获取当前奖池余额
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    //获取生成随机数个数
    function getNumword() public pure returns (uint) {
        return NUM_WORDS;
    }

    //获取请求确认数
    function getRequestConfirmations() public pure returns (uint) {
        return REQUEST_CONFIRMATIONS;
    }

    //获取请求gas限制
    function getCallbackGasLimit() public view returns (uint) {
        return i_callbackGasLimit;
    }

    //获取奖池（合约）地址
    function getLottertAddress() public view returns (address) {
        return address(this);
    }
}
