// SPDX-License-Identifier: MIT

//COMPILER: v0.8.7+commit.e28d00a7.js
// Enable optimization: 开启并使用默认值200
pragma solidity ^0.8.0;

import "./abstracts/ERC20.sol";
import "./abstracts/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./abstracts/Context.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./abstracts/TokenDividendTracker.sol";
// import "./libraries/Clones.sol";
import "./interfaces/IUniswapV2Factory.sol";





//入口
//contract选择tugou01合约进行部署
contract tugou01 is ERC20, Ownable {

    //引入SafeMath
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address public  uniswapV2Pair;

    bool private swapping;

    TokenDividendTracker public dividendTracker;

    address public rewardToken;

    uint256 public swapTokensAtAmount;

    uint256 public buyTokenRewardsFee;
    uint256 public sellTokenRewardsFee;
    uint256 public buyLiquidityFee;
    uint256 public sellLiquidityFee;
    uint256 public buyMarketingFee;
    uint256 public sellMarketingFee;
    uint256 public buyDeadFee;
    uint256 public sellDeadFee;
    uint256 public AmountLiquidityFee;
    uint256 public AmountTokenRewardsFee;
    uint256 public AmountMarketingFee;

    address public _marketingWalletAddress;

    //销毁地址
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    //事件判断
    mapping(address => bool) public _isEnemy;

    uint256 public gasForProcessing;

    // 费用支出和最大交易金额
    mapping (address => bool) private _isExcludedFromFees;

        
     
    // 自动做市商配对的门店地址。有没有转到这些地址
    // 可能会受到最高转账金额的限制
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    //constructor deployer 构造
    //部署的时候因为这里是需要发送0.2bnb的手续费，所以我们需要在value的地方提前写入0.2+18个0，也就是2+18个0
    constructor(
        // 代币名称
        string memory name_,
        // 代币符号
        string memory symbol_,
        // 发行量
        uint256 totalSupply_,
        //分红代币的合约，注意一定是部署公链（币安链）上的，比如usdt的合约，或者本合约
        //0x75caa28db4341e392067f0ce27b9ede2dc7a31ab
        address rewardAddr_,
        //市场营销钱包，自己的
        //0x5C8375CfFA8859e75d633cC31EaD5450c166e2A0
        address marketingWalletAddr_,
        //[X,X,X,X] (X是数字，也就是百分比，分别对应分红、流动性、市场营销、燃烧，参考[1,1,1,2]) 这个4个加起来不能抄过25，
        //[1,1,1,2]
        uint256[4] memory buyFeeSetting_, 
        //[4,3,2,1]
        // [X,X,X,X] 同上
        uint256[4] memory sellFeeSetting_,
        //持有多少代币参与分红，单位是wei，所以数量后要加18个0
        uint256 tokenBalanceForReward_
    ) payable ERC20(name_, symbol_)  {
        rewardToken = rewardAddr_;
        _marketingWalletAddress = marketingWalletAddr_;

        buyTokenRewardsFee = buyFeeSetting_[0];
        buyLiquidityFee = buyFeeSetting_[1];
        buyMarketingFee = buyFeeSetting_[2];
        buyDeadFee = buyFeeSetting_[3];

        sellTokenRewardsFee = sellFeeSetting_[0];
        sellLiquidityFee = sellFeeSetting_[1];
        sellMarketingFee = sellFeeSetting_[2];
        sellDeadFee = sellFeeSetting_[3];
        //[X,X,X,X] 这个4个加起来不能抄过25，这个地方可以改上限
        require(buyTokenRewardsFee.add(buyLiquidityFee).add(buyMarketingFee).add(buyDeadFee) <= 25, "Total purchase cost exceeds 25%");
        require(sellTokenRewardsFee.add(sellLiquidityFee).add(sellMarketingFee).add(sellDeadFee) <= 25, "Total sales expense exceeds 25%");

        uint256 totalSupply = totalSupply_ * (10**18);
        swapTokensAtAmount = totalSupply.mul(2).div(10**6); // 0.002%

        
        //默认情况下，使用300000天然气处理自动索赔股息
        gasForProcessing = 300000;
        //這個不知道怎麽改
        // dividendTracker = TokenDividendTracker(
        //     // payable(Clones.clone(serviceAddr_))
        //         payable();
        // );
        // dividendTracker.initialize{value: msg.value}(rewardToken,tokenBalanceForReward_);
    
        dividendTracker = new TokenDividendTracker(rewardToken, tokenBalanceForReward_);
        /**
            bsc测试网相关参数：
                薄饼测试网路由，源码676行:0xB6BA90af76D139AB3170c7df0139636dB6120F7e -》对应下面的地址。
                测试网usdt:0xEdA5dA0050e21e9E34fadb1075986Af1370c7BDb
                测试网SHIB: 0x11e815a78Cc41D733Db00f06B3A96074855362CE
                测试网依赖合约:0x72519BE1b6fcd1493378e38628ba60Dc34DeB41f
                
            bsc主网：    
                薄饼Swap路由: 0x10ED43C718714eb63d5aA57B78B54704E256024E
                    USDT: 0x55d398326f99059fF775485246999027B3197955
                    ETH: 0x2170Ed0880ac9A755fd29B2688956BD959F933F8
                    SHIB: 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D
                    DOGE: 0xbA2aE424d960c26247Dd6c32edC70B295c744C43
            这个路由合约可以在eth换成uniswap，在goerli上部署uniswap路由，作为测试。
            没水了，goerli网络：
                这个部署的直接把代码copy过来用metamask部署
                部署的uniwap路由：
                部署的pancakeswap路由：
            Moonbeam测试网（Moonbase Alpha）：
                https://apps.moonbeam.network/moonbase-alpha/faucet/
                部署的usdt:https://moonbase.moonscan.io/address/0x75caa28db4341e392067f0ce27b9ede2dc7a31ab
                部署的uniswap:
                    工厂合约：https://moonbase.moonscan.io/address/0xcd1b8685e6dcec471510b53dfc9a8cf2e2be5e17
                    路由合约：https://moonbase.moonscan.io/address/0xe2d05990fE091A1664D70D65Cb7B1eb651eF0724
                    ，这个路由合约需要：wth9合约：https://goerli.etherscan.io/address/0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6#code
        */
       //UniswapV2路由合约的函数选择器和事件选择器
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xe2d05990fE091A1664D70D65Cb7B1eb651eF0724);
        // require(IERC20(rewardAddr_).totalSupply() > 0 && rewardAddr_ != _uniswapV2Router.WETH(), "Invalid Reward Token ");
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
         // 不接受股息
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // 不包括支付费用或拥有最高交易金额
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        
        _cast(owner(), totalSupply);
    }

    // 一个合约只能有一个receive函数，该函数不能有参数和返回值，需设置为external，payable
    // 当本合约收到ether但并未被调用任何函数，未接受任何数据，receive函数被触发
    receive() external payable {}

    function updateMinimumTokenBalanceForDividends(uint256 val) public onlyOwner {
        dividendTracker.setMinimumTokenBalanceForDividends(val);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        if(_isExcludedFromFees[account] != excluded){
            _isExcludedFromFees[account] = excluded;
            emit ExcludeFromFees(account, excluded);
        }
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    // 设置营销钱包
    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
    }
 // 无法从automatedmarketmakerpairs中删除煎饼交换对
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Cannot delete pancake exchange pairs from automatedmarketmakerpairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function EnemyAddress(address account, bool value) external onlyOwner{
        _isEnemy[account] = value;
    }

    // 汽车做市商配对设置为该值
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Auto market maker pairing is set to this value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    // 更新预处理
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Gas treatment must be between 200000 and 500000");
        require(newValue != gasForProcessing, "Cannot update gasforprocessing to the same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    function isExcludedFromDividends(address account) public view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }
  // 进程红利跟踪器
    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
  // 宣称
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function swapManual() public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        require(contractTokenBalance > 0 , "token balance zero");
        swapping = true;
        if(AmountLiquidityFee > 0) swapAndLiquify(AmountLiquidityFee);
        if(AmountTokenRewardsFee > 0) swapAndSendDividends(AmountTokenRewardsFee);
        if(AmountMarketingFee > 0) swapAndSendToFee(AmountMarketingFee);
        swapping = false;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }

    function setDeadWallet(address addr) public onlyOwner {
        deadWallet = addr;
    }
    function setBuyLiquidityFee(uint256 amount) public onlyOwner {
        buyLiquidityFee = amount;
    }
    function setSellLiquidityFee(uint256 amount) public onlyOwner {
        sellLiquidityFee = amount;
    }
    function setBuyTokenRewardsFee(uint256 amount) public onlyOwner {
        buyTokenRewardsFee = amount;
    }
    function setSellTokenRewardsFee(uint256 amount) public onlyOwner {
        sellTokenRewardsFee = amount;
    }
    function setBuyMarketingFee(uint256 amount) public onlyOwner {
        buyMarketingFee = amount;
    }
    function setSellMarketingFee(uint256 amount) public onlyOwner {
        sellMarketingFee = amount;
    }
    function setBuyDeadFee(uint256 amount) public onlyOwner {
        buyDeadFee = amount;
    }
    function setSellDeadFee(uint256 amount) public onlyOwner {
        sellDeadFee = amount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isEnemy[from] && !_isEnemy[to], 'Enemy address');

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            if(AmountMarketingFee > 0) swapAndSendToFee(AmountMarketingFee);
            if(AmountLiquidityFee > 0) swapAndLiquify(AmountLiquidityFee);
            if(AmountTokenRewardsFee > 0) swapAndSendDividends(AmountTokenRewardsFee);
            swapping = false;
        }


        bool takeFee = !swapping;
            // 如果任何账户属于_isexcluded from fee account，则删除该费用
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees;
            uint256 LFee;
            uint256 RFee;
            uint256 MFee;
            uint256 DFee;
            if(automatedMarketMakerPairs[from]){
                LFee = amount.mul(buyLiquidityFee).div(100);
                AmountLiquidityFee += LFee;
                RFee = amount.mul(buyTokenRewardsFee).div(100);
                AmountTokenRewardsFee += RFee;
                MFee = amount.mul(buyMarketingFee).div(100);
                AmountMarketingFee += MFee;
                DFee = amount.mul(buyDeadFee).div(100);
                fees = LFee.add(RFee).add(MFee).add(DFee);
            }
            if(automatedMarketMakerPairs[to]){
                LFee = amount.mul(sellLiquidityFee).div(100);
                AmountLiquidityFee += LFee;
                RFee = amount.mul(sellTokenRewardsFee).div(100);
                AmountTokenRewardsFee += RFee;
                MFee = amount.mul(sellMarketingFee).div(100);
                AmountMarketingFee += MFee;
                DFee = amount.mul(sellDeadFee).div(100);
                fees = LFee.add(RFee).add(MFee).add(DFee);
            }
            amount = amount.sub(fees);
            if(DFee > 0) super._transfer(from, deadWallet, DFee);
            super._transfer(from, address(this), fees.sub(DFee));
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
        }
    }

    function swapAndSendToFee(uint256 tokens) private  {
        uint256 initialCAKEBalance = IERC20(rewardToken).balanceOf(address(this));
        swapTokensForCake(tokens);
        uint256 newBalance = (IERC20(rewardToken).balanceOf(address(this))).sub(initialCAKEBalance);
        IERC20(rewardToken).transfer(_marketingWalletAddress, newBalance);
        AmountMarketingFee = AmountMarketingFee - tokens;
    }
    // 交换和液化
    function swapAndLiquify(uint256 tokens) private {
          // 把合同余额分成两半
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;
        // 用代币换以太币
        swapTokensForEth(half); // <-触发swap+liquify时，这会中断ETH->仇恨交换

           // 我们刚刚换了多少钱
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // 为uniswap增加流动性
        addLiquidity(otherHalf, newBalance);
        AmountLiquidityFee = AmountLiquidityFee - tokens;
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
          // 生成令牌->weth的uniswap对路径
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function swapTokensForCake(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = rewardToken;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            address(0),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForCake(tokens);
        AmountTokenRewardsFee = AmountTokenRewardsFee - tokens;
        uint256 dividends = IERC20(rewardToken).balanceOf(address(this));
        bool success = IERC20(rewardToken).transfer(address(dividendTracker), dividends);
        if (success) {
            dividendTracker.distributeCAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}



