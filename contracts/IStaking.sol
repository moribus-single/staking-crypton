//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Interface of the staking protocol for ERC20 tokens.
 */
interface IStaking {
    /**
     * @dev moves `value` of tokens from sender to the contract
     */
    function stake(uint256 value) external;

    /**
     * @dev moves all of the rewards to the sender
     */
    function claim() external;

    /**
     * @dev moves back `value` of tokens from the contract to sender
     */
    function unstake(uint256 value) external;

    /**
     * @dev Emits when `amount` tokens are staked.
     */
    event Staked(
        address indexed staker, 
        uint256 indexed amount,
        uint256 missed
    );

    /**
     * @dev Emits when `amount` tokens are claimed.
     */
    event Claimed(
        address indexed staker,
        uint256 indexed amount
    );

    /**
     * @dev Emits when `amount` tokens are unstaked.
     */
    event Unstaked(
        address indexed staker,
        uint256 indexed amount,
        uint256 allowed
    );
}