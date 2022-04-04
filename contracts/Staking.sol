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
        uint256 rewardProduced;
        uint256 totalStaked;
        uint256 tps;
        uint256 timeInit;
        uint256 lastUpdated;
        uint256 decimals;
    }

    struct Staker {
        uint256 totalAmount;
        uint256 missedRewards;
        uint256 gainRewards;
        uint256 availableRewards;
        uint256 claimed;
    }

    StakingInfo public stakingInfo;

    mapping(address => Staker) public users;

    constructor(
        address _token, 
        uint256 _reward, 
        uint256 _epochDuration
    ) {
        stakingInfo = StakingInfo({
            token: _token,
            epochReward: _reward,
            epochDuration: _epochDuration * 3600,
            rewardProduced: 100,
            totalStaked: 0,
            tps: 0,
            timeInit: block.timestamp,
            lastUpdated: block.timestamp,
            decimals: 10 ** 18
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
        console.log("new reward =", (user.totalAmount * stakingInfo.tps - user.missedRewards) / stakingInfo.decimals - user.gainRewards);
        user.availableRewards += (user.totalAmount * stakingInfo.tps - user.missedRewards) / stakingInfo.decimals - user.gainRewards;

        stakingInfo.totalStaked += value;

        return true;
    }

    function withdraw() external override returns (bool) {
        _updateState();

        Staker storage user = users[msg.sender];
        user.availableRewards = user.totalAmount * stakingInfo.tps - user.missedRewards;
        
        IERC20(stakingInfo.token).transfer(
            msg.sender, 
            user.availableRewards / stakingInfo.decimals + user.gainRewards
        );

        user.claimed = user.availableRewards / stakingInfo.decimals;
        user.gainRewards = 0;
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

        user.gainRewards = value * stakingInfo.tps / stakingInfo.decimals; 
        console.log("gained =", user.gainRewards);

        IERC20(stakingInfo.token).transfer(
            msg.sender,
            value
        );

        user.totalAmount -= value;

        return true;
    }

    function TPS() external returns (uint256) {
        _updateState();

        return stakingInfo.tps;
    }

    function user() external returns (Staker memory info) {
        _updateState();

        Staker storage user = users[msg.sender];
        console.log("tps =", stakingInfo.tps);
        user.availableRewards = (stakingInfo.tps * user.totalAmount - user.missedRewards) / stakingInfo.decimals - user.claimed;

        return user;
    }

    function _updateState() internal {
        uint256 offset = (block.timestamp - stakingInfo.lastUpdated) / stakingInfo.epochDuration;

        if (offset > 0) {
            stakingInfo.rewardProduced += offset * stakingInfo.epochReward;
            stakingInfo.tps += offset * stakingInfo.epochReward * stakingInfo.decimals / stakingInfo.totalStaked;
            stakingInfo.lastUpdated = block.timestamp;
        }
    }
}
