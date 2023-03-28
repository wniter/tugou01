// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// 引入防止运算溢出的安全库
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev 将两个int256变量相乘，溢出时失败
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // 将MIN_INT256与-1相乘时检测溢出
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev 两个int256变量的除法，溢出时失败
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // 在将MIN_INT256除以-1时防止溢出
        require(b != -1 || a != MIN_INT256);

        // 实度除以0时已抛出
        return a / b;
    }

    /**
     * @dev 减去两个int256变量，溢出失败
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev 添加两个int256变量，溢出时失败
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev 转换为绝对值，溢出时失败
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}