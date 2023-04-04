
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../abstracts/Context.sol";

import "../libraries/SafeMath.sol";
/**
 * 参考链接：https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 * @title 
 * @author 
 * @notice 
 */
contract ERC20 is Context, IERC20, IERC20Metadata {

    // 引入SafeMath安全数学运算库，避免数学运算整型溢出
    using SafeMath for uint256;


    // 用mapping保存每个地址对应的余额
    mapping(address => uint256) private _balances;

  // 存储对账号的控制 
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
   /**
     * @dev 设置 {name} 和 {symbol} 的值
     *
     *{decimals}的默认值是18。要为其选择其他值{decimals}你应该让它过载。
     *
     * 所有这两个值都是不可变的：在运行期间只能设置一次
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    /**
     * @dev 返回令牌的名称
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    /**
     * 获取总供应量
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * 获取某个地址的余额
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    /**
     * 转账
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    /**
     *  获取被授权令牌余额,获取 _owner 地址授权给 _spender 地址可以转移的令牌的余额
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    /**
     * 授权，允许 spender 地址从你的账户中转移 amount 个令牌到任何地方
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {    
        // 调用内部函数_approve设置调用者对spender的授权值
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * 代理转账函数，调用者代理代币持有者sender向指定地址recipient转账一定数量amount代币
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
   /**
     * 增加授权值函数，调用者增加对spender的授权值
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * 减少授权值函数，调用者减少对spender的授权值
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    /**
     * 转账
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * 铸币
     */
    function _mint(address account, uint256 amount) internal virtual {
          // 非零地址检查
        require(account != address(0), "ERC20: cast to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        // 更新代币总量
        _totalSupply = _totalSupply.add(amount);
        // 修改代币销毁地址account的代币余额
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
      }

   /**
     * 代币销毁
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    /**
     * 批准_spender能从合约调用账户中转出数量为amount的token
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        // 非零地址检查
        require(spender != address(0), "ERC20: approve to the zero address");
        // 设置owner对spender的授权值为amount
        _allowances[owner][spender] = amount;
        // 触发Approval事件
        emit Approval(owner, spender, amount);
    }

 
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}