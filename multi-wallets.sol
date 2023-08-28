// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

error PancakeSwapBuyer__NotOwner();

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external; 
}

contract multiWallets {
    address private immutable SwapRouter;
    address private constant WBNB_ADDRESS = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private immutable contractAddress = address(this);
    address private immutable i_owner;
    address private immutable i_contractFather;
    IUniswapV2Router02 private pancakeswapRouter;
   
    modifier onlyFather(){
        if(msg.sender != i_contractFather){
            revert PancakeSwapBuyer__NotOwner();
        }
        _;
    }
    modifier onlyOwner(){
        if(msg.sender != msg.sender){
            revert PancakeSwapBuyer__NotOwner();
        }
        _;
    }
    constructor(address contractFather, address uniswap) {
        SwapRouter = uniswap;
        pancakeswapRouter =  IUniswapV2Router02(SwapRouter);
        i_contractFather = contractFather;
        i_owner = msg.sender;
    }
    function sellToken(address tokenAddress) external onlyFather{
        address[] memory path = new address[](2);
        path[1] = WBNB_ADDRESS;
        path[0] = tokenAddress;

        uint256 deadline = block.timestamp +10000;
        IERC20 ierc20 = IERC20(tokenAddress);
        uint256 balance = ierc20.balanceOf(contractAddress);
        ierc20.approve(SwapRouter, balance);
        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 0, path, i_owner, deadline);
        //ierc20.transferFrom(contractAddress, s_contractFather, balance);
    }
    function transferToken(address tokenAddress, address recipientAddress, uint256 amount) external onlyFather {
        IERC20 ierc20 = IERC20(tokenAddress);
        //uint256 balance = ierc20.balanceOf(contractAddress);
        ierc20.approve(contractAddress, amount);
        ierc20.transferFrom(contractAddress, recipientAddress, amount);
    }
   
    receive () external payable {
        (bool success, ) = payable(i_contractFather).call{value: msg.value}("");
        if(!success){
            revert("Clr Fail");
        }
    }
    function getTokenBalance(address tokenAddress) external view onlyFather returns (uint256){
        return IERC20(tokenAddress).balanceOf(contractAddress);
    }
}
