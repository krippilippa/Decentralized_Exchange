// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

// *** TEST TOKEN TO USE IN EXCHANGE ***

contract Link is ERC20 {
    constructor() ERC20("Chainlink", "LINK"){
        _mint(msg.sender, 1000);
    }
}