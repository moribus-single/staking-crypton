//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Staking protocol for ERC20 token.
 * @dev Implementation of the {IStaking} interface.
 */
contract Staking is IStaking {
    using SafeERC20 for IERC20;

    struct StakingInfo {
        IERC20 asset;
        uint256 reward;
        uint256 duration;
        uint256 staked;
        uint256 tps;
        uint256 update;
    }

    struct Staker {
        uint256 amount;
        uint256 missed;
        uint256 allowed;
        uint256 claimed;
    }

    /**
     * @dev The presicion all of the computes.
     */
    uint256 public immutable PRESICION;

    /**
     * @dev Contains essential information about staking protocol.
     * 
     * NOTE: atributes of the struct
     * 
     *  reward - Reward produced in epoch.
     *  duration - Epoch duration in hours.
     *  staked - Total amount of tokens staked in contract.
     *  tps - Tokens per staked one.
     *  update - Timestamp of the last update.
     */
    StakingInfo public stakingInfo;

    /**
     * @dev Mapping of stakers of the contract.
     *
     * NOTE: atributes of the struct
     *
     *  amount - Total amount of the tokens staked by particular staker.
     *  missed - Total amount of the missed tokens since start of protocol existence.
     *  allowed - Total amount of the allowed tokens for claiming.
     *  claimed - Total amount of the claimed tokens.
     *
     */
    mapping(address => Staker) public users;

    /**
     * @dev Update state variables - {stakingInfo.tps} and {stakingInfo.update}
     *
     * NOTE: Use in functions changing state.
     */
    modifier updateState() {
        _updateState();
        _;
    }

    /**
     * @dev Set the values for {stakinfInfo}.
     */
    constructor(
        address _asset, 
        uint256 _reward, 
        uint256 _epochDuration,
        uint256 _presicion
    ) {
        stakingInfo = StakingInfo({
            asset: IERC20(_asset),
            reward: _reward,
            duration: _epochDuration * 3600,
            staked: 0,
            tps: 0,
            update: block.timestamp
        });

        PRESICION = _presicion;
    }

    /**
     * @dev See {IStaking-stake}.
     */
    function stake(uint256 value) external updateState override {
        stakingInfo.asset.safeTransferFrom(
            msg.sender,
            address(this), 
            value
        );

        Staker storage user = users[msg.sender];
        user.amount += value;
        user.missed += value * stakingInfo.tps;

        stakingInfo.staked += value;

        emit Staked(
            msg.sender, 
            value, 
            user.missed
        );
    }

    /**
     * @dev See {IStaking-claim}.
     */
    function claim() external updateState override {
        Staker storage user = users[msg.sender];

        uint256 totalRewards = (user.amount * stakingInfo.tps - user.missed) / PRESICION + user.allowed;
        uint256 availableRewards = totalRewards > user.claimed ? (totalRewards - user.claimed) : 0;

        require(
            availableRewards > 0,
            "nothing to claim"
        );

        user.claimed += availableRewards;
        user.allowed = 0;

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
    function unstake(uint256 value) external updateState override {
        Staker storage user = users[msg.sender];
        require(
            user.amount >= value,
            "not enough to unstake"
        );

        user.allowed += value * stakingInfo.tps / PRESICION; 
        user.amount -= value;
        stakingInfo.staked -= value;

        stakingInfo.asset.safeTransfer(
            msg.sender,
            value
        );

        emit Unstaked(
            msg.sender, 
            value, 
            user.allowed
        );
    }

    /**
     * @dev Set {stakingInfo.epochReward}
     */
    function setEpochReward(uint256 value) external {
        stakingInfo.reward = value;
    }

    /**
     * @dev Set {stakingInfo.duration}
     */
    function setEpochDuration(uint256 amount) external {
        stakingInfo.duration = amount * 3600;
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

        uint256 epochId = (block.timestamp - stakingInfo.update) / stakingInfo.duration;
        uint256 tps = stakingInfo.tps + epochId * stakingInfo.reward * PRESICION / stakingInfo.staked;

        uint256 totalRewards = (user.amount * tps - user.missed) / PRESICION + user.allowed;
        uint256 availableRewards = totalRewards > user.claimed ? (totalRewards - user.claimed) : 0;

        return availableRewards;
    }

    /**
     * @dev Update state variables.
     *
     * NOTE: Called in updateState modifier
     */
    function _updateState() internal {
        uint256 epochId = (block.timestamp - stakingInfo.update) / stakingInfo.duration;

        if (epochId > 0) {
            stakingInfo.tps += epochId * stakingInfo.reward * PRESICION / stakingInfo.staked;
            stakingInfo.update = block.timestamp;
        }
    }
}
