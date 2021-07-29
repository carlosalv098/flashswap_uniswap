// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../interfaces/IUniswap.sol';
import '../interfaces/IUniswapV2Callee.sol';
import 'hardhat/console.sol';

contract Flashswap_uniswap is IUniswapV2Callee {

    using SafeMath for uint;

    address public owner;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'only owner functionality');
        _;
    }

    event Log(string details, uint value);

    function flashswap(address _token_to_borrow, uint _amount_to_borrow) onlyOwner() external {
        // check if the pair exists on Uniswap
        address pair = IUniswapV2Factory(FACTORY).getPair(_token_to_borrow, WETH);
        require(pair != address(0), 'pair does not exist on Uniswap');

        // if the pair address exists, get the two token addresses
        address token_0 = IUniswapV2Pair(pair).token0();
        address token_1 = IUniswapV2Pair(pair).token1();

        // determine amount_0_out and amount_1_out based on token_0 and token_1 addresses
        // if token_to_borrow == token_0 then amount_0_out = amount_to_borrow, otherwise amount_0_out = 0
        uint amount_0_out = _token_to_borrow == token_0 ? _amount_to_borrow : 0;
        uint amount_1_out = _token_to_borrow == token_1 ? _amount_to_borrow : 0;

        // more data can be added here, in case even add more parameters in this function
        // this could be a struct too
        bytes memory data = abi.encode(_token_to_borrow, _amount_to_borrow);

        // some data is required to trigger a flashswap
        IUniswapV2Pair(pair).swap(amount_0_out, amount_1_out, address(this), data);

    }

    // this fuunction receives the flashloan, here we have to repay the amount plus fees
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {

        // the msg.sender of this function has to be the PAIR address, so we check
        // first get the two token addresses
        address token_0 = IUniswapV2Pair(msg.sender).token0();
        address token_1 = IUniswapV2Pair(msg.sender).token1();

        // once we have the two addresses use IUniswapV2Factory to get the pair address
        address pair = IUniswapV2Factory(FACTORY).getPair(token_0, token_1);

        // check msg.sender is the pair address
        require(msg.sender == pair, 'msg.sender is not the pair address');

        // check contract that started the flashloan is this constract
        require(_sender == address(this), 'address of the sender is not the address of this contract');

        // extract data, because it is encoded
        (address token_to_borrow, uint _amount_to_borrow) = abi.decode(_data, (address, uint));

        // calculate the fee
        uint fee = ((_amount_to_borrow * 3) / 997) + 1;
        uint amount_to_repay = _amount_to_borrow.add(fee);

        // do something with the tokens arbitrage, etc...

        console.log('amount to borrow %s',_amount_to_borrow);
        console.log('token to borrow %s', token_to_borrow);
        console.log('amount_0 %s', _amount0);
        console.log('amount_1 %s', _amount1);
        console.log('fee: %s', fee);
        console.log('amount to repay %s', amount_to_repay);

        // repay
        IERC20(token_to_borrow).transfer(pair, amount_to_repay);

    }

}
