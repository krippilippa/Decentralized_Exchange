// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable{

    using SafeMath for uint256;

    // "Accepted" tokens information
    struct Token{
        bytes32 ticker;
        address tokenAddress;
    }

    // Storage of the tokens
    mapping(bytes32 => Token) public tokenMapping;
    bytes32[] public tokenList;

    // A mapping to keep track of different tokens owned by an address
    // bytes32 is used since we cannot compare stirngs in solidity
    mapping (address => mapping(bytes32 => uint256)) public balances;

    // Check if token exists in our exhange
    modifier tokenExists(bytes32 _ticker){
        require(tokenMapping[_ticker].tokenAddress != address(0), "ticker does not exist in exhange");
        _;
    }

    // Add a token to the exhange, only for the owner
    function addToken(bytes32 _ticker, address _tokenAddress) onlyOwner external{
        tokenMapping[_ticker] = Token(_ticker, _tokenAddress);
        tokenList.push(_ticker);
    }

    // Deposti funds from an address to the exhange, has to have an allowance
    function deposit(uint256 _amount, bytes32 _ticker) tokenExists(_ticker) external{
        IERC20(tokenMapping[_ticker].tokenAddress).transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender][_ticker] = balances[msg.sender][_ticker].add(_amount);
    }

    function depositEth() payable external {
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add(msg.value);
    }

    // Withdraw tokens from the exhange
    function withdraw(uint256 _amount, bytes32 _ticker) tokenExists(_ticker) external{
        require(balances[msg.sender][_ticker] >= _amount, "Balance not sufficient");
        // Using safemath to not get under/over flow
        balances[msg.sender][_ticker] = balances[msg.sender][_ticker].sub(_amount);
        IERC20(tokenMapping[_ticker].tokenAddress).transfer(msg.sender, _amount);
    }
}