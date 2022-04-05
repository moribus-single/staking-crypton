//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Staking protocol for ERC20
 * @dev Implementation of the {IStaking} interface.
 */
contract Staking is IStaking {
    using SafeERC20 for IERC20;

    struct StakingInfo {
        IERC20 asset;
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
     * @dev Set the values for {stakinfInfo}.
     */
    constructor(
        address _asset, 
        uint256 _reward, 
        uint256 _epochDuration
    ) {
        stakingInfo = StakingInfo({
            asset: IERC20(_asset),
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
    function stake(uint256 value) external override {
        _updateState();

        Staker storage user = users[msg.sender];
        user.totalAmount += value;
        user.missedRewards += value * stakingInfo.tps;

        stakingInfo.totalStaked += value;

        stakingInfo.asset.safeTransferFrom(
            msg.sender,
            address(this), 
            value
        );

        emit Staked(
            msg.sender, 
            value, 
            user.missedRewards
        );
    }

    /**
     * @dev See {IStaking-claim}.
     */
    function claim() external override {
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

        stakingInfo.asset.safeTransfer(
            msg.sender,
            availableRewards
        );

        emit Claimed(
            msg.sender, 
            availableRewards
        );
    }

    /**
     * @dev See {IStaking-unstake}.
     */
    function unstake(uint256 value) external override {
        _updateState();

        Staker storage user = users[msg.sender];
        require(
            user.totalAmount >= value,
            "not enough to unstake"
        );

        user.allowedRewards += value * stakingInfo.tps / PRESICION; 
        user.totalAmount -= value;
        stakingInfo.totalStaked -= value;

        stakingInfo.asset.safeTransfer(
            msg.sender,
            value
        );

        emit Unstaked(
            msg.sender, 
            value, 
            user.allowedRewards
        );
    }

    /**
     * @dev Set {stakingInfo.epochReward}
     */
    function setEpochReward(uint256 value) external {
        stakingInfo.epochReward = value;
    }

    /**
     * @dev Set {stakingInfo.epochDuration}
     */
    function setEpochDuration(uint256 amount) external {
        stakingInfo.epochDuration = amount * 3600;
    }

    /**
     * @dev Return the information about the user.
     */
    function getInfo() external view returns (Staker memory) {
        return users[msg.sender];
    }

    /**
     * @dev Return the actual rewards of the sender.
     */
    function getRewards() external view returns (uint256) {
        Staker storage user = users[msg.sender];

        uint256 epochId = (block.timestamp - stakingInfo.lastUpdated) / stakingInfo.epochDuration;
        uint256 tps = stakingInfo.tps + epochId * stakingInfo.epochReward * PRESICION / stakingInfo.totalStaked;

        uint256 totalRewards = (user.totalAmount * tps - user.missedRewards) / PRESICION + user.allowedRewards;
        uint256 availableRewards = totalRewards > user.claimed ? (totalRewards - user.claimed) : 0;

        return availableRewards;
    }

    /**
     * @dev Update state variables - {stakingInfo.tps} and {stakingInfo.lastUpdated}
     */
    function _updateState() internal {
        uint256 epochId = (block.timestamp - stakingInfo.lastUpdated) / stakingInfo.epochDuration;

        if (epochId > 0) {
            stakingInfo.tps += epochId * stakingInfo.epochReward * PRESICION / stakingInfo.totalStaked;
            stakingInfo.lastUpdated = block.timestamp;
        }
    }
}
