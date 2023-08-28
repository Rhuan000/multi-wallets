// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

error PcsSellBuy__NotOwner();
error PcsSellBuy__NotEnoughEthInContract();
error PcsSellBuy__TransactionFailed();
error PcsSellBuy__AddContractWalletFirst();
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,address[] calldata path,address to,uint deadline) external payable; 
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amount);
}
interface ImultiWallets {
    function sellToken(address tokenAddress) external;
    function transferToken(address tokenAddres, address recipientAddress, uint256 amount) external;
    function getTokenBalance(address tokenAddress) external view returns (uint256);
    function clearBalance() external payable;
}

contract pcsSellBuy{
    //testnet wbnb: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
    //mainnet wbnb: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address private constant WBNB_ADDRESS = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    uint256 private constant transactiontest = 0.0000001 ether;
    address private immutable contractAddress = address(this);
    address private immutable i_owner;
    address private immutable UniswapAddress;
    uint8 private constant expectedTokenAmount = 0;
    uint256 public s_amount;
    address[] private s_wallets;
    
    //ImultiWallet private multiWalletAddress;
    IUniswapV2Router02 private pancakeswapRouter;
    modifier onlyOwner(){
        require(msg.sender == i_owner, "What are you trying? :P ");
        _;
    }
    constructor(address uniswapaddress) {
        UniswapAddress = uniswapaddress;
        pancakeswapRouter = IUniswapV2Router02(uniswapaddress);
        i_owner = msg.sender;
    }
    /**@dev Adding new children's addresses */
    function Add_Wallet(address[] calldata _wallets) external onlyOwner{
            address[] memory wallets = s_wallets;
            for(uint8 i = 0; i < _wallets.length; i++){
                for(uint8 ii = 0; ii < wallets.length; ii++){
                require(wallets[ii] != _wallets[i], "You already put this wallet.");
                }
                s_wallets.push(_wallets[i]);
            }
        }
    /**@dev Buying and sending to my children's addresses */
    function Complex_Buy(address tokenAddress, bool test, uint8 index, uint256 buyPerWallet, uint8 deadlineSec, uint8 sllipagePercentage) external  payable onlyOwner{
        address[] memory _wallets = s_wallets;
        if(_wallets.length < index){
            revert PcsSellBuy__AddContractWalletFirst();
        }
        uint256 sllipage;
        address[] memory path = new address[](2);
        path[0] = WBNB_ADDRESS;
        path[1] = tokenAddress;
        uint256[] memory amounts = pancakeswapRouter.getAmountsOut(buyPerWallet, path);
        sllipage = (amounts[1] * sllipagePercentage) / 100;        
        // Calculate 70% of the expected amount
        uint256 deadline = block.timestamp + deadlineSec;
        // Testing the buy, if i'm not blacklisted, so its safe.
        if(test){
            pancakeswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: transactiontest}(sllipage, path, _wallets[0], deadline);
            ImultiWallets(_wallets[0]).sellToken(tokenAddress);
        }
        // Buying tokens.
        for(uint8 i = 0; i < index; i++){
            pancakeswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: buyPerWallet }(expectedTokenAmount, path, _wallets[i], deadline);
        } 
    }
    function Test_Buy(address tokenAddress, uint8 index, uint256 deadlineSec, uint256 sllipagePercentage) external payable onlyOwner{
        address testWallet = s_wallets[0];
        address[] memory path = new address[](2);
        path[0] = WBNB_ADDRESS;
        path[1] = tokenAddress;
        uint256 deadline = block.timestamp + deadlineSec;
        // Testing the buy, if i'm not blacklisted, so its safe.
        uint256[] memory amounts = pancakeswapRouter.getAmountsOut(msg.value, path);
        uint256 sllipage = (amounts[1] * sllipagePercentage) / 100; 
        pancakeswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: transactiontest}(sllipage, path, testWallet, deadline);
        ImultiWallets(testWallet).sellToken(tokenAddress);
        
        pancakeswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value - transactiontest}(expectedTokenAmount, path, s_wallets[index], deadline);
    }

    function Simple_Buy(address tokenAddress, uint8 index, uint256 deadlineSec, uint256 sllipagePercentage) external payable onlyOwner{
        address[] memory path = new address[](2);
        path[0] = WBNB_ADDRESS;
        path[1] = tokenAddress;
        uint256 deadline = block.timestamp + deadlineSec;
        uint256[] memory amounts = pancakeswapRouter.getAmountsOut(msg.value, path);
        uint256 sllipage = (amounts[1] * sllipagePercentage) / 100; 

        pancakeswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(sllipage, path, s_wallets[index], deadline);
    }
    /**@dev Tranfering the childs amount to address(this) and selling. */
    function Sell(address tokenAddress, bool multiWallets, uint8 startIndex, uint8 finalIndex) external onlyOwner{
        // Sellling the tokens.
        if(multiWallets){
            address[] memory _wallets = s_wallets;
            for(startIndex; startIndex < finalIndex;startIndex++){
            ImultiWallets(_wallets[startIndex]).sellToken(tokenAddress);
            }
        }
        else {
            ImultiWallets(s_wallets[startIndex]).sellToken(tokenAddress);
        }
    }
    function TransferTokenFromChild(address tokenAddress, address recipientAddress, bool multiWallets, uint8 index, uint256 amount) external onlyOwner {
        if(multiWallets){
            address[] memory _wallets = s_wallets;
            for(uint8 i = 0; i < index; index++){
                ImultiWallets(_wallets[index]).transferToken(tokenAddress, recipientAddress, amount);
            }
        }    
        else {
            ImultiWallets(s_wallets[index]).transferToken(tokenAddress, recipientAddress, amount);
        }
    }
    function CheckWalletBalance(address tokenAddress, bool multiWallets, uint8 index) public view onlyOwner returns(uint256[] memory) {
        uint256[] memory balances = new uint256[](multiWallets ? s_wallets.length - index : 1);
        if (multiWallets) {
            for (uint8 i = index; i < s_wallets.length; i++) {
                balances[i - index] = ImultiWallets(s_wallets[i]).getTokenBalance(tokenAddress);
            }
        }
        else {
            balances[0] = ImultiWallets(s_wallets[index]).getTokenBalance(tokenAddress);
        }

        return balances;
    }
    function Withdraw () external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: contractAddress.balance}("");
        if(!success){
            revert PcsSellBuy__TransactionFailed();
        }
    }
    receive () external payable {}
    function getBalance() public view onlyOwner returns(uint256){
        return (address(this).balance);
    }
    function getWallets () public view onlyOwner returns(address[] memory){
        return s_wallets;
    }
}

