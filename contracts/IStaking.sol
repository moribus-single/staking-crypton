//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Interface of the staking protocol for ERC20 tokens.
 */
interface IStaking {
    /**
     * @dev moves `value` of tokens from sender to the contract
     */
    function stake(uint256 value) external returns (bool);

    /**
     * @dev moves all of the rewards to the sender
     */
    function claim() external returns (bool);

    /**
     * @dev moves back `value` of tokens from the contract to sender
     */
     function unstake(uint256 value) external returns (bool);
}