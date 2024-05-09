// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

error Lottery_Error_EntranceFee();

contract Lottery {
    /**Event */
    //抽奖人事件
    event lotteryEnter(address indexed player);

    /**state Variables */
    //入场费
    uint256 private immutable s_i_entranceFee;

    //记录抽奖人
    address payable[] private s_players;

    constructor(uint256 _entranceFee) {
        s_i_entranceFee = _entranceFee;
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
    // function pickRandomWinner() public {}

    //查看入场费
    function getEntranceFee() public view returns (uint256) {
        return s_i_entranceFee;
    }

    //获取抽奖人
    function getPlayers(uint16 _index) public view returns (address) {
        return s_players[_index];
    }
}
