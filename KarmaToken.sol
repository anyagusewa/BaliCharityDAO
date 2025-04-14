// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KarmaToken is ERC20 {
    address public crowdfund;

    constructor() ERC20("KarmaToken", "KRM") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function setCrowdfund(address _crowdfund) external {
        require(crowdfund == address(0), "Crowdfund already set");
        crowdfund = _crowdfund;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == crowdfund, "Only KarmaCrowdfund can mint");
        _mint(to, amount);
    }
}
