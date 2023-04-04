
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
// abstract 抽象合约将合约的定义与其实现脱钩，从而提供了更好的可扩展性和自文档性
// 简化了诸如Template方法的模式，并消除了代码重复
// 提供有关当前执行上下文的信息，包括事务的发送者及其数据。 虽然这些通常可以通过 msg.sender 和 msg.data 获得，但不应以这种直接方式访问它们，因为在处理元交易时，发送和支付执行的帐户可能不是实际的发送者（就应用而言）。
// 只有中间的、类似程序集的合约才需要这个合约。
abstract contract Context {
      // contract 合约

    // internal 修饰的变量和函数，任何用户或者合约都能调用和访问
    // private修饰的变量和函数，只能在其所在的合约中调用和访问，即使是其子合约也没有权限访问
    // internal 和 private 类似，不过，如果某个合约继承自其父合约，这个合约即可以访问父合约中定义的“内部”函数
    // external 与public 类似，只不过这些函数只能在合约之外调用 - 它们不能被合约内的其他函数调用

    // 在你计划重写的每个非接口函数定义前增加virtual关键字。对所有未实现的外部接口函数增加virtual关键字
    // 在单个继承时，在每个重写的方法前增加override关键字
    // 有多重继承时，必须在括号中依次列出定义该函数的基类。如果多个基类定义了相同的函数，继承的合约必须重写所有冲突的函数


    // msg.data (bytes):完整的calldata  msg.sender (address):消息的发送方(调用者)
    //内部函数_msgSender，获取函数调用者地址
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    //内部函数，获取调用者的data
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}