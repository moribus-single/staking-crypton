//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./IStaking.sol";
import "./Token.sol";

/**
 * @dev Implementation of the {IStaking} interface.
 */
contract Staking is IStaking {
    struct StakingInfo {
        address asset;
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
        uint256 claimed;
    }

    StakingInfo public stakingInfo;

    /**
     * @dev Mapping of stakers of the contract.
     */
    mapping(address => Staker) public users;

    /**
     * @dev The presicion all of the computes.
     */
    uint256 constant public PRESICION = 10 ** 18;

    /**
     * @dev Sets the values for {stakinfInfo}.
     */
    constructor(
        address _token, 
        uint256 _reward, 
        uint256 _epochDuration
    ) {
        stakingInfo = StakingInfo({
            asset: _token,
            epochReward: _reward,
            epochDuration: _epochDuration * 3600,
            totalStaked: 0,
            tps: 0,
            lastUpdated: block.timestamp
        });
    }

    /**
     * @dev See {IStaking-stake}.
     */
    function stake(uint256 value) external override returns (bool) {
        _updateState();

        Token(stakingInfo.asset).transferFrom(
            msg.sender,
            address(this), 
            value
        );

        Staker storage user = users[msg.sender];
        user.totalAmount += value;
        user.missedRewards += value * stakingInfo.tps;

        stakingInfo.totalStaked += value;

        return true;
    }

    /**
     * @dev See {IStaking-claim}.
     */
    function claim() external override returns (bool) {
        _updateState();

        Staker storage user = users[msg.sender];

        uint256 totalRewards = (user.totalAmount * stakingInfo.tps - user.missedRewards) / PRESICION + user.allowedRewards;
        uint256 availableRewards = totalRewards > user.claimed ? (totalRewards - user.claimed) : 0;

        require(
            availableRewards > 0,
            "nothing to claim"
        );

        user.claimed += availableRewards;
        user.allowedRewards = 0;

        IERC20(stakingInfo.asset).transfer(
            msg.sender, 
            availableRewards
        );

        return true;
    }

    /**
     * @dev See {IStaking-unstake}.
     */
    function unstake(uint256 value) external override returns (bool) {
        _updateState();

        Staker storage user = users[msg.sender];
        require(
            user.totalAmount >= value,
            "not enough to unstake"
        );

        user.allowedRewards += value * stakingInfo.tps / PRESICION; 

        IERC20(stakingInfo.asset).transfer(
            msg.sender,
            value
        );

        user.totalAmount -= value;
        stakingInfo.totalStaked -= value;

        return true;
    }

    /**
     * @dev Returns the information about user.
     */
    function getInfo() external view returns (Staker memory) {
        return users[msg.sender];
    }

    function getRewards() external view returns (uint256) {
        Staker storage user = users[msg.sender];

        uint256 totalRewards = (user.totalAmount * stakingInfo.tps - user.missedRewards) / PRESICION + user.allowedRewards;
        uint256 availableRewards = totalRewards > user.claimed ? (totalRewards - user.claimed) : 0;

        return availableRewards;
    }

    /**
     * @dev Updates state variables - {stakingInfo.tps} and {stakingInfo.lastUpdated}
     */
    function _updateState() internal {
        uint256 epochId = (block.timestamp - stakingInfo.lastUpdated) / stakingInfo.epochDuration;

        if (epochId > 0) {
            stakingInfo.tps += epochId * stakingInfo.epochReward * PRESICION / stakingInfo.totalStaked;
            stakingInfo.lastUpdated = block.timestamp;
        }
    }
}
