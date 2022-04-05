//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC20 token for staking protocol
 */
contract Token is ERC20, Ownable{
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address owner, uint256 amount) public onlyOwner {
        _burn(owner, amount);
    }
}