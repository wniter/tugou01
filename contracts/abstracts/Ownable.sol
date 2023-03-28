

pragma solidity ^0.8.0;

import "../abstracts/Context.sol";

// Solidity支持多继承和多态，实验的方式是通过直接的代码拷贝
// 当一个合约从多个合约继承的时候，只有一个合约（子类）会被部署到区块链上，而其他的代码会被拷贝到这个单一的合约中去
// Solidity的继承方式和Python的极为类似，主要的区别在与Solidity支持多继承，而Python不支持
abstract contract Ownable is Context {
    address private _owner;

    // web3或ethers类事件过滤时,solidity事件定义必须添加的属性，可以在事件参数上增加`indexed`属性，最多对三个参数增加这个属性
    // 加上这个属性，可以允许你在web3.js或ethes.js中通过对加了这个属性的参数进行值过滤
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // 表示在合约部署后，第一个调用的方法
    constructor() {
        _transferOwnership(_msgSender());
    }

    // 获取所有者地址
    function owner() public view virtual returns (address) {
        return _owner;
    }
  // 设置公共筛选条件
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
  // 放弃所有权
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 // 更换合约所有者
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
// 初始化方法，将部署者的地址作为自己的oldOwner，还具有更换所有者的功能
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
