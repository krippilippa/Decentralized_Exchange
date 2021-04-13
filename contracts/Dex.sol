// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Wallet.sol";

contract Dex is Wallet{

    using SafeMath for uint256;

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
    }

    uint public orderIdCounter;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 _ticker, Side _side) view public returns (Order[] memory){
        return(orderBook[_ticker][uint(_side)]);
    }

    function createLimitOrder(Side _side, bytes32 _ticker, uint _amount, uint _price) public {
        if(_side == Side.BUY){
            require(balances[msg.sender]["ETH"] >= _amount.mul(_price));
        }
        else if(_side == Side.SELL){
            require(balances[msg.sender][_ticker] >= _amount);
        }

        Order[] storage orders = orderBook[_ticker][uint(_side)];
        orders.push(
            Order(orderIdCounter, msg.sender, _side, _ticker, _amount, _price, 0)
        );

        uint i = orders.length > 0 ? orders.length - 1 : 0;
        if(_side == Side.BUY){
            while (i > 0){
                if(orders[i-1].price > orders[i].price){
                    break;
                }
                else{
                    Order memory temp = orders[i];
                    orders[i]= orders[i-1];
                    orders[i-1] = temp;
                    i--;
                }
            }
        }
        else if(_side == Side.SELL){
             while (i > 0){
                if(orders[i-1].price < orders[i].price){
                    break;
                }
                else{
                    Order memory temp = orders[i];
                    orders[i]= orders[i-1];
                    orders[i-1] = temp;
                    i--;
                }
            }
        }

        orderIdCounter++;
    }
    
    function createMarketOrder(Side _side, bytes32 _ticker, uint _amount) public{
        uint orderBookSide;
        if(_side == Side.BUY){
            orderBookSide = 1;
        }else{ // if the user is creating a SELL order of a token
            require(balances[msg.sender][_ticker] >= _amount, "Not enough tokens to sell");
            orderBookSide = 0;
        }

        Order[] storage orders = orderBook[_ticker][orderBookSide];

        uint totalFilled = 0;

        for (uint256 i = 0; i < orders.length && totalFilled < _amount; i++) {
            uint leftToFill = _amount.sub(totalFilled);
            uint availableToFill = orders[i].amount.sub(orders[i].filled);
            uint filled = 0;
            if(availableToFill > leftToFill){
                filled = leftToFill; //Fill the entire market order
            }
            else{ 
                filled = availableToFill; //Fill as much as is available in order[i]
            }

            totalFilled = totalFilled.add(filled);
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);

            if(_side == Side.BUY){
                //Verify that the buyer has enough ETH
                require(balances[msg.sender]["ETH"] >= cost);
                //msg.sender is the buyer
                balances[msg.sender][_ticker] = balances[msg.sender][_ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);
                
                balances[orders[i].trader][_ticker] = balances[orders[i].trader][_ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
            }
            else if(_side == Side.SELL){
                //Msg.sender is the seller
                balances[msg.sender][_ticker] = balances[msg.sender][_ticker].sub(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);
                
                balances[orders[i].trader][_ticker] = balances[orders[i].trader][_ticker].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);
            }
        }
        
        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            // Remove the top element in the orders array by overwriting every element
            // with the next element in the order list
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
    }
}
