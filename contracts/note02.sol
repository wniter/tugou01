
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;



import "./abstracts/Context.sol";
import "./interfaces/IERC20.sol";
import "./abstracts/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";

// 、、测试
// https://zhuanlan.zhihu.com/p/400572792
 /**
   #BEE
   
   #LIQ+#RFI+#SHIB+#DOGE = #BEE

   #EagleSwap features:
   3% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders
   I created a black hole so #Bee token will deflate itself in supply with every transaction
   50% Supply is burned at start.
   

 */
contract tugou04 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    // 默认余额
    mapping (address => uint256) private _rOwned;
    // 排除余额[实际余额]
    mapping (address => uint256) private _tOwned;
    // 授权
    mapping (address => mapping (address => uint256)) private _allowances;

    // 排除列表
    mapping (address => bool) private _isExcluded;
     // 排除列表
    address[] private _excluded;
    
    //constant MAX
    uint256 private constant MAX = ~uint256(0);
    
    // 排除流通量[实际流通量]
    uint256 private _tTotal = 500000000 * 10**6 * 10**9;
    
    // 默认余额
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    
     // 累计手续费
    uint256 private _tFeeTotal;

    //这个地方自定义 name 和 symbol
    string private _name = 'tugou04';
    string private _symbol = 'tugou04';
    
    //精度
    uint8 private _decimals = 9;
    
    // 最大持有手续费 
    uint256  public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    // 大于该值可进行添加Uni流动性
    uint256 public _burnFee = 6;
    uint256 private _previousBurnFee = _burnFee;
    
    //销毁地址
    address public burnAdd = 0x000000000000000000000000000000000000dEaD;
    
    uint private _max_tx_size = 200000 * 10**6 * 10**9;

    constructor () public {
          // 把币mint给创建者
        _rOwned[_msgSender()] = _rTotal;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    // 流通量
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
      // 余额
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
  // 转账
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
// 查询授权
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
        // 授权
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 // 授权转账
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
   // 增加授权
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
// 减少授权
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
//  是否被排除
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
   // 累计手续费
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
// 用户把余额变成手续费
    function deliver(uint256 tAmount) public {
        //操作人
        address sender = _msgSender();
          // 排除地址不能进行操作
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
            // 计算对应的默认数量
        (uint256 rAmount,,,,,) = _getValues(tAmount);
       // 扣除余额
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // 减少流通量
        _rTotal = _rTotal.sub(rAmount);
        // 添加手续费总量
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
 // 计算排除数量对应的默认数量 或者到账的默认数量
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
   // 计算实际余额
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
   // 把一个账户进行排除操作
    function excludeAccount(address account) external onlyOwner() {
        //require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
   // 取消一个排除账户的排除状态
    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    //这个可以抄ERC20
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(sender != owner() && recipient != owner())
            require(amount <= _max_tx_size, "Transfer amount exceeds the maxTxAmount.");

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, burnAdd, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, burnAdd, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, burnAdd, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, burnAdd, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    //  //这个可以抄ERC20
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn);
        return (tTransferAmount, tFee, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }
    // 获取默认流通量和排除流通量的比例
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _burn(uint256 burn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = burn.mul(currentRate);
        _rOwned[burnAdd] = _rOwned[burnAdd].add(rBurn);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _burnFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;

        _taxFee = 0;
        _burnFee = 0;
    }
       // 恢复手续费率
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
    }
    
    function _getTaxFee() public view returns(uint256) {
        return _taxFee;
    }

    function _getBurnFee() public view returns(uint256) {
        return _burnFee;
    }

    function _getMaxTxAmount() public view returns(uint256){
        return _max_tx_size;
    }

    function _setTaxFee(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function _setBurnFee(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

}

// contract EGONSWAP is Context, IERC20, Ownable {
//     using SafeMath for uint256;
//     using Address for address;
    
   
//     mapping (address => uint256) private _rOwned;

//     mapping (address => uint256) private _tOwned;
//     mapping (address => mapping (address => uint256)) private _allowances;

//     mapping (address => bool) private _isExcludedFromFee;

//     mapping (address => bool) private _isExcluded;
//     address[] private _excluded;
   
//     uint256 private constant MAX = ~uint256(0);
//     uint256 private _tTotal = 1000000000 * 10**6 * 10**9;

//     uint256 private _rTotal = (MAX - (MAX % _tTotal));
//     uint256 private _tFeeTotal;

//     string private _name = "EagleSwap";
//     string private _symbol = "EGON";
//     uint8 private _decimals = 9;
    
//     uint256 public _taxFee = 3;
//     uint256 private _previousTaxFee = _taxFee;
    
//     uint256 public _liquidityFee = 3;
//     uint256 private _previousLiquidityFee = _liquidityFee;

//     IUniswapV2Router02 public immutable uniswapV2Router;
//     address public immutable uniswapV2Pair;
    
//     bool inSwapAndLiquify;
//     bool public swapAndLiquifyEnabled = true;
    
//     uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
//     uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;
    
//     event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
//     event SwapAndLiquifyEnabledUpdated(bool enabled);
//     event SwapAndLiquify(
//         uint256 tokensSwapped,
//         uint256 ethReceived,
//         uint256 tokensIntoLiqudity
//     );
    
//     modifier lockTheSwap {
//         inSwapAndLiquify = true;
//         _;
//         inSwapAndLiquify = false;
//     }
    
//     constructor () public {
//         _rOwned[_msgSender()] = _rTotal;
        
//         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
//          // Create a uniswap pair for this new token
//         uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
//             .createPair(address(this), _uniswapV2Router.WETH());

//         // set the rest of the contract variables
//         uniswapV2Router = _uniswapV2Router;
        
//         //exclude owner and this contract from fee
//         _isExcludedFromFee[owner()] = true;
//         _isExcludedFromFee[address(this)] = true;
        
//         emit Transfer(address(0), _msgSender(), _tTotal);
//     }

//     function name() public view returns (string memory) {
//         return _name;
//     }

//     function symbol() public view returns (string memory) {
//         return _symbol;
//     }

//     function decimals() public view returns (uint8) {
//         return _decimals;
//     }

//     function totalSupply() public view override returns (uint256) {
//         return _tTotal;
//     }

//     function balanceOf(address account) public view override returns (uint256) {
//         if (_isExcluded[account]) return _tOwned[account];
//         return tokenFromReflection(_rOwned[account]);
//     }

//     function transfer(address recipient, uint256 amount) public override returns (bool) {
//         _transfer(_msgSender(), recipient, amount);
//         return true;
//     }

//     function allowance(address owner, address spender) public view override returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     function approve(address spender, uint256 amount) public override returns (bool) {
//         _approve(_msgSender(), spender, amount);
//         return true;
//     }

//     function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
//         _transfer(sender, recipient, amount);
//         _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
//         return true;
//     }

//     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
//         return true;
//     }

//     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
//         return true;
//     }

//     function isExcludedFromReward(address account) public view returns (bool) {
//         return _isExcluded[account];
//     }

//     function totalFees() public view returns (uint256) {
//         return _tFeeTotal;
//     }

//     function deliver(uint256 tAmount) public {
//         address sender = _msgSender();
//         require(!_isExcluded[sender], "Excluded addresses cannot call this function");
//         (uint256 rAmount,,,,,) = _getValues(tAmount);
//         _rOwned[sender] = _rOwned[sender].sub(rAmount);
//         _rTotal = _rTotal.sub(rAmount);
//         _tFeeTotal = _tFeeTotal.add(tAmount);
//     }

//     function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
//         require(tAmount <= _tTotal, "Amount must be less than supply");
//         if (!deductTransferFee) {
//             (uint256 rAmount,,,,,) = _getValues(tAmount);
//             return rAmount;
//         } else {
//             (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
//             return rTransferAmount;
//         }
//     }

//     function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
//         require(rAmount <= _rTotal, "Amount must be less than total reflections");
//         uint256 currentRate =  _getRate();
//         return rAmount.div(currentRate);
//     }

//     function excludeFromReward(address account) public onlyOwner() {
//         // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
//         require(!_isExcluded[account], "Account is already excluded");
//         if(_rOwned[account] > 0) {
//             _tOwned[account] = tokenFromReflection(_rOwned[account]);
//         }
//         _isExcluded[account] = true;
//         _excluded.push(account);
//     }

//     function includeInReward(address account) external onlyOwner() {
//         require(_isExcluded[account], "Account is already excluded");
//         for (uint256 i = 0; i < _excluded.length; i++) {
//             if (_excluded[i] == account) {
//                 _excluded[i] = _excluded[_excluded.length - 1];
//                 _tOwned[account] = 0;
//                 _isExcluded[account] = false;
//                 _excluded.pop();
//                 break;
//             }
//         }
//     }
//         function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
//         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
//         _tOwned[sender] = _tOwned[sender].sub(tAmount);
//         _rOwned[sender] = _rOwned[sender].sub(rAmount);
//         _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
//         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
//         _takeLiquidity(tLiquidity);
//         _reflectFee(rFee, tFee);
//         emit Transfer(sender, recipient, tTransferAmount);
//     }
    
//         function excludeFromFee(address account) public onlyOwner {
//         _isExcludedFromFee[account] = true;
//     }
    
//     function includeInFee(address account) public onlyOwner {
//         _isExcludedFromFee[account] = false;
//     }
    
//     function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
//         _taxFee = taxFee;
//     }
    
//     function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
//         _liquidityFee = liquidityFee;
//     }
   
//     function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
//         _maxTxAmount = _tTotal.mul(maxTxPercent).div(
//             10**2
//         );
//     }

//     function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
//         swapAndLiquifyEnabled = _enabled;
//         emit SwapAndLiquifyEnabledUpdated(_enabled);
//     }
    
//      //to recieve ETH from uniswapV2Router when swaping
//     receive() external payable {}

//     function _reflectFee(uint256 rFee, uint256 tFee) private {
//         _rTotal = _rTotal.sub(rFee);
//         _tFeeTotal = _tFeeTotal.add(tFee);
//     }

//     function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
//         (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
//         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
//         return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
//     }

//     function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
//         uint256 tFee = calculateTaxFee(tAmount);
//         uint256 tLiquidity = calculateLiquidityFee(tAmount);
//         uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
//         return (tTransferAmount, tFee, tLiquidity);
//     }

//     function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
//         uint256 rAmount = tAmount.mul(currentRate);
//         uint256 rFee = tFee.mul(currentRate);
//         uint256 rLiquidity = tLiquidity.mul(currentRate);
//         uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
//         return (rAmount, rTransferAmount, rFee);
//     }

//     function _getRate() private view returns(uint256) {
//         (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
//         return rSupply.div(tSupply);
//     }

//     function _getCurrentSupply() private view returns(uint256, uint256) {
//         uint256 rSupply = _rTotal;
//         uint256 tSupply = _tTotal;      
//         for (uint256 i = 0; i < _excluded.length; i++) {
//             if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
//             rSupply = rSupply.sub(_rOwned[_excluded[i]]);
//             tSupply = tSupply.sub(_tOwned[_excluded[i]]);
//         }
//         if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
//         return (rSupply, tSupply);
//     }
    
//     function _takeLiquidity(uint256 tLiquidity) private {
//         uint256 currentRate =  _getRate();
//         uint256 rLiquidity = tLiquidity.mul(currentRate);
//         _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
//         if(_isExcluded[address(this)])
//             _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
//     }
    
//     function calculateTaxFee(uint256 _amount) private view returns (uint256) {
//         return _amount.mul(_taxFee).div(
//             10**2
//         );
//     }

//     function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
//         return _amount.mul(_liquidityFee).div(
//             10**2
//         );
//     }
    
//     function removeAllFee() private {
//         if(_taxFee == 0 && _liquidityFee == 0) return;
        
//         _previousTaxFee = _taxFee;
//         _previousLiquidityFee = _liquidityFee;
        
//         _taxFee = 0;
//         _liquidityFee = 0;
//     }
    
//     function restoreAllFee() private {
//         _taxFee = _previousTaxFee;
//         _liquidityFee = _previousLiquidityFee;
//     }
    
//     function isExcludedFromFee(address account) public view returns(bool) {
//         return _isExcludedFromFee[account];
//     }

//     function _approve(address owner, address spender, uint256 amount) private {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//     function _transfer(
//         address from,
//         address to,
//         uint256 amount
//     ) private {
//         require(from != address(0), "ERC20: transfer from the zero address");
//         require(to != address(0), "ERC20: transfer to the zero address");
//         require(amount > 0, "Transfer amount must be greater than zero");
//         if(from != owner() && to != owner())
//             require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

//         // is the token balance of this contract address over the min number of
//         // tokens that we need to initiate a swap + liquidity lock?
//         // also, don't get caught in a circular liquidity event.
//         // also, don't swap & liquify if sender is uniswap pair.
//         uint256 contractTokenBalance = balanceOf(address(this));
        
//         if(contractTokenBalance >= _maxTxAmount)
//         {
//             contractTokenBalance = _maxTxAmount;
//         }
        
//         bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
//         if (
//             overMinTokenBalance &&
//             !inSwapAndLiquify &&
//             from != uniswapV2Pair &&
//             swapAndLiquifyEnabled
//         ) {
//             contractTokenBalance = numTokensSellToAddToLiquidity;
//             //add liquidity
//             swapAndLiquify(contractTokenBalance);
//         }
        
//         //indicates if fee should be deducted from transfer
//         bool takeFee = true;
        
//         //if any account belongs to _isExcludedFromFee account then remove the fee
//         if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
//             takeFee = false;
//         }
        
//         //transfer amount, it will take tax, burn, liquidity fee
//         _tokenTransfer(from,to,amount,takeFee);
//     }

//     function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
//         // split the contract balance into halves
//         uint256 half = contractTokenBalance.div(2);
//         uint256 otherHalf = contractTokenBalance.sub(half);

//         // capture the contract's current ETH balance.
//         // this is so that we can capture exactly the amount of ETH that the
//         // swap creates, and not make the liquidity event include any ETH that
//         // has been manually sent to the contract
//         uint256 initialBalance = address(this).balance;

//         // swap tokens for ETH
//         swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

//         // how much ETH did we just swap into?
//         uint256 newBalance = address(this).balance.sub(initialBalance);

//         // add liquidity to uniswap
//         addLiquidity(otherHalf, newBalance);
        
//         emit SwapAndLiquify(half, newBalance, otherHalf);
//     }

//     function swapTokensForEth(uint256 tokenAmount) private {
//         // generate the uniswap pair path of token -> weth
//         address[] memory path = new address[](2);
//         path[0] = address(this);
//         path[1] = uniswapV2Router.WETH();

//         _approve(address(this), address(uniswapV2Router), tokenAmount);

//         // make the swap
//         uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
//             tokenAmount,
//             0, // accept any amount of ETH
//             path,
//             address(this),
//             block.timestamp
//         );
//     }

//     function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
//         // approve token transfer to cover all possible scenarios
//         _approve(address(this), address(uniswapV2Router), tokenAmount);

//         // add the liquidity
//         uniswapV2Router.addLiquidityETH{value: ethAmount}(
//             address(this),
//             tokenAmount,
//             0, // slippage is unavoidable
//             0, // slippage is unavoidable
//             owner(),
//             block.timestamp
//         );
//     }

//     //this method is responsible for taking all fee, if takeFee is true
//     function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
//         if(!takeFee)
//             removeAllFee();
        
//         if (_isExcluded[sender] && !_isExcluded[recipient]) {
//             _transferFromExcluded(sender, recipient, amount);
//         } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
//             _transferToExcluded(sender, recipient, amount);
//         } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
//             _transferStandard(sender, recipient, amount);
//         } else if (_isExcluded[sender] && _isExcluded[recipient]) {
//             _transferBothExcluded(sender, recipient, amount);
//         } else {
//             _transferStandard(sender, recipient, amount);
//         }
        
//         if(!takeFee)
//             restoreAllFee();
//     }

//     function _transferStandard(address sender, address recipient, uint256 tAmount) private {
//         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
//         _rOwned[sender] = _rOwned[sender].sub(rAmount);
//         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
//         _takeLiquidity(tLiquidity);
//         _reflectFee(rFee, tFee);
//         emit Transfer(sender, recipient, tTransferAmount);
//     }

//     function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
//         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
//         _rOwned[sender] = _rOwned[sender].sub(rAmount);
//         _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
//         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
//         _takeLiquidity(tLiquidity);
//         _reflectFee(rFee, tFee);
//         emit Transfer(sender, recipient, tTransferAmount);
//     }

//     function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
//         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
//         _tOwned[sender] = _tOwned[sender].sub(tAmount);
//         _rOwned[sender] = _rOwned[sender].sub(rAmount);
//         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
//         _takeLiquidity(tLiquidity);
//         _reflectFee(rFee, tFee);
//         emit Transfer(sender, recipient, tTransferAmount);
//     }


    

// }