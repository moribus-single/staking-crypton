//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./IStaking.sol";
import "./Token.sol";

contract Staking is IStaking {
    struct StakingInfo {
        address token;
        uint256 epochReward;
        uint256 epochDuration;
        uint256 totalStaked;
        uint256 tps;
        uint256 lastUpdated;
    }

    struct Staker {
        uint256 totalAmount;
        uint256 missedRewards;
        uint256 allowedRewards;
        uint256 availableRewards;
        uint256 claimed;
    }

    StakingInfo public stakingInfo;

    mapping(address => Staker) public users;

    uint256 constant public PRESICION = 10 ** 18;

    constructor(
        address _token, 
        uint256 _reward, 
        uint256 _epochDuration
    ) {
        stakingInfo = StakingInfo({
            token: _token,
            epochReward: _reward,
            epochDuration: _epochDuration * 3600,
            totalStaked: 0,
            tps: 0,
            lastUpdated: block.timestamp
        });
    }

    function stake(uint256 value) external override returns (bool) {
        _updateState();

        Token(stakingInfo.token).transferFrom(
            msg.sender,
            address(this), 
            value
        );

        Staker storage user = users[msg.sender];
        user.totalAmount += value;
        user.missedRewards += value * stakingInfo.tps;
        user.availableRewards += (user.totalAmount * stakingInfo.tps - user.missedRewards) / PRESICION - user.allowedRewards;

        stakingInfo.totalStaked += value;

        return true;
    }

    function claim() external override returns (bool) {
        _updateState();

        Staker storage user = users[msg.sender];
        user.availableRewards = user.totalAmount * stakingInfo.tps - user.missedRewards;
        
        IERC20(stakingInfo.token).transfer(
            msg.sender, 
            user.availableRewards / PRESICION + user.allowedRewards
        );

        user.claimed += user.availableRewards / PRESICION + user.allowedRewards;
        user.allowedRewards = 0;
        user.availableRewards = 0;

        return true;
    }

    function unstake(uint256 value) external returns (bool) {
        _updateState();
        stakingInfo.totalStaked -= value;

        Staker storage user = users[msg.sender];
        require(
            user.totalAmount >= value,
            "not enough to unstake"
        );

        user.allowedRewards += value * stakingInfo.tps / PRESICION; 

        IERC20(stakingInfo.token).transfer(
            msg.sender,
            value
        );

        user.totalAmount -= value;

        return true;
    }

    function getInfo() external view returns (Staker memory info) {
        return users[msg.sender];
    }

    function _updateState() internal {
        uint256 offset = (block.timestamp - stakingInfo.lastUpdated) / stakingInfo.epochDuration;

        if (offset > 0) {
            stakingInfo.tps += offset * stakingInfo.epochReward * PRESICION / stakingInfo.totalStaked;
            stakingInfo.lastUpdated = block.timestamp;
        }
    }
}
