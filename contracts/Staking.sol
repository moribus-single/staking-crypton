//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./IStaking.sol";
import "./Token.sol";

contract Staking is IStaking {
    uint256 public epochId;
    uint256 public epochReward;
    uint256 public epochDuration;
    uint256 public rewardProduced;

    uint256 public timeUpdated;
    uint256 public decimals;
    address public token;

    struct Staker {
        uint256 timeUpdated;
        uint256 stakes;
        uint256 missedRewards;
        uint256 availableRewards;
    }

    struct Epoch {
        uint256 totalStaked;
        uint256 TPS;
    }

    mapping(address => Staker) public users;
    mapping(uint256 => Epoch) public epochs;

    constructor(
        address _token, 
        uint256 _reward, 
        uint256 _epochDuration
    ) {
        token = _token;
        epochDuration = _epochDuration * 1 hours;
        decimals = 10**18;

        epochReward = _reward;   
        timeUpdated = block.timestamp;
    }

    function stake(uint value) external override returns (bool) {
        Token(token).transferFrom(msg.sender, address(this), value);

        Epoch storage currEpoch = epochs[epochId];
        Staker storage user = users[msg.sender];

        user.stakes += value;
        user.missedRewards += currEpoch.TPS * value; 
        user.timeUpdated = block.timestamp;

        uint256 offset = (block.timestamp - timeUpdated) / epochDuration;
        if(offset > 0) {
            _updateTPS(offset);

            Epoch storage offseted = epochs[epochId + offset];
            offseted.totalStaked += epochs[epochId + offset - 1].totalStaked + value;
            epochId += offset;
        }
        else{
            currEpoch.totalStaked += value;
        }

        Epoch storage epochUpdated = epochs[epochId];
        user.availableRewards = epochUpdated.TPS * user.stakes - user.missedRewards;

        return true;
    }

    function withdraw() external override returns (bool) {
        uint256 offset = (block.timestamp - timeUpdated) / epochDuration;
        if(offset > 0) {
            _updateTPS(offset);
            epochs[epochId + offset].totalStaked += epochs[epochId + offset - 1].totalStaked;
            epochId += offset;

            _updateUserInfo(msg.sender);
        }

        IERC20(token).transfer(
            msg.sender, 
            users[msg.sender].availableRewards
        );

        Staker storage user = users[msg.sender];
        user.availableRewards = 0;

        return true;
    }

    function totalStakes(uint256 id) external returns (uint256) {
        if(epochs[id].totalStaked == 0) {
            Epoch storage epoch = epochs[id];
            epoch.totalStaked += epochs[id - 1].totalStaked ;         
        }

        return epochs[id].totalStaked;
    }

    function TPS() external returns (uint256) {
        uint256 offset = (block.timestamp - timeUpdated) / epochDuration;
        if(offset > 0) {
            _updateTPS(offset);

            epochs[epochId + offset].totalStaked += epochs[epochId + offset - 1].totalStaked;
            epochId += offset;
        }

        return epochs[epochId].TPS;
    }

    function user() external returns (Staker memory info) {
        Staker storage user = users[msg.sender];

        uint256 offset = (block.timestamp - timeUpdated) / epochDuration;
        if(offset > 0) {
            _updateTPS(offset);
            epochs[epochId + offset].totalStaked += epochs[epochId + offset - 1].totalStaked;
            epochId += offset;
        }
        _updateUserInfo(msg.sender);

        return users[msg.sender];
    }

    function _updateTPS(uint256 offset) internal {
        for(uint256 i = epochId; i < epochId + offset; i++) {
            Epoch storage epoch = epochs[i];
            Epoch storage currEpoch = epochs[epochId + offset];

            if(epoch.totalStaked == 0) {
                epoch.totalStaked += epochs[i-1].totalStaked;                         
            }

            currEpoch.TPS += epoch.TPS + epochReward * decimals / epoch.totalStaked;
        }

        timeUpdated = block.timestamp;
    }

    function _updateUserInfo(
        address sender
    ) internal {
        Staker storage user = users[sender];
        Epoch storage epoch = epochs[epochId];

        user.availableRewards = epoch.TPS * user.stakes - user.missedRewards;
        user.timeUpdated = block.timestamp;
    }
}
