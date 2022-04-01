//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Interface of the staking for ERC20 token.
 */
interface IStaking {
    /**
     * @dev moves `value` of tokens from sender to the contract
     */
    function stake(uint256 value) external returns (bool);

    /**
     * @dev moves all of the rewards to the sender
     */
    function withdraw() external returns (bool);
}