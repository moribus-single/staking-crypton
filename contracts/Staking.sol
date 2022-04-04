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
        Staker storage user = users[msg.sender];
        user.missedRewards += value * stakingInfo.tps;

        _updateState();

        Token(stakingInfo.token).transferFrom(
            msg.sender,
            address(this), 
            value
        );

        // Staker storage user = users[msg.sender];
        user.totalAmount += value;
        // user.missedRewards += value * stakingInfo.tps;
        user.availableRewards = (user.totalAmount * stakingInfo.tps - user.missedRewards) / stakingInfo.decimals;

        stakingInfo.totalStaked += value;

        return true;
    }

    function withdraw() external override returns (bool) {
        _updateState();

        Staker storage user = users[msg.sender];
        user.availableRewards = user.totalAmount * stakingInfo.tps - user.missedRewards;
        
        IERC20(stakingInfo.token).transfer(
            msg.sender, 
            user.availableRewards / stakingInfo.decimals
        );

        user.gainRewards = user.availableRewards;
        user.availableRewards = 0;

        return true;
    }

    // function unstake(uint256 value) external returns (bool) {
    //     _updateState();

    //     Staker storage user = users[msg.sender];
    //     require(
    //         user.totalAmount >= value,
    //         "not enough to unstake"
    //     );

    //     IERC20(stakingInfo.token).transfer(
    //         msg.sender,
    //         value
    //     );

    //     user.totalAmount -= value;

    //     return true;
    // }

    function TPS() external returns (uint256) {
        _updateState();

        return stakingInfo.tps;
    }

    function user() external returns (Staker memory info) {
        _updateState();

        Staker storage user = users[msg.sender];
        console.log("tps =", stakingInfo.tps);
        console.log("totalAmount =", user.missedRewards);
        user.availableRewards = (stakingInfo.tps * user.totalAmount - user.missedRewards) / stakingInfo.decimals;

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
