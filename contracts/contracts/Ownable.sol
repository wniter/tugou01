// // SPDX-License-Identifier: MIT
// // OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "../abstracts/Context.sol";

// /**
//  * @dev Contract module which provides a basic access control mechanism, where
//  * there is an account (an owner) that can be granted exclusive access to
//  * specific functions.
//  *
//  * By default, the owner account will be the one that deploys the contract. This
//  * can later be changed with {transferOwnership}.
//  *
//  * This module is used through inheritance. It will make available the modifier
//  * `onlyOwner`, which can be applied to your functions to restrict their use to
//  * the owner.
//  */
// abstract contract Ownable is Context {
//     address private _owner;


//     //锁仓时间，这个时间可否自定义？
//     address private _previousOwner;
//     uint256 private _lockTime;

//     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//     /**
//      * @dev Initializes the contract setting the deployer as the initial owner.
//      */
//     constructor() {
//         _transferOwnership(_msgSender());
//     }

//     /**
//      * @dev Throws if called by any account other than the owner.
//      */
//     modifier onlyOwner() {
//         _checkOwner();
//         _;
//     }

//     /**
//      * @dev Returns the address of the current owner.
//      */
//     function owner() public view virtual returns (address) {
//         return _owner;
//     }

//     /**
//      * @dev Throws if the sender is not the owner.
//      */
//     function _checkOwner() internal view virtual {
//         require(owner() == _msgSender(), "Ownable: caller is not the owner");
//     }

//     /**
//      * @dev Leaves the contract without owner. It will not be possible to call
//      * `onlyOwner` functions anymore. Can only be called by the current owner.
//      *
//      * NOTE: Renouncing ownership will leave the contract without an owner,
//      * thereby removing any functionality that is only available to the owner.
//      */
//     function renounceOwnership() public virtual onlyOwner {
//         _transferOwnership(address(0));
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Can only be called by the current owner.
//      */
//     function transferOwnership(address newOwner) public virtual onlyOwner {
//         require(newOwner != address(0), "Ownable: new owner is the zero address");
//         _transferOwnership(newOwner);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Internal function without access restriction.
//      */
//     function _transferOwnership(address newOwner) internal virtual {
//         address oldOwner = _owner;
//         _owner = newOwner;
//         emit OwnershipTransferred(oldOwner, newOwner);
//     }

//     function geUnlockTime() public view returns (uint256) {
//         return _lockTime;
//     }

//     //Locks the contract for owner for the amount of time provided
//     function lock(uint256 time) public virtual onlyOwner {
//         _previousOwner = _owner;
//         _owner = address(0);
//         _lockTime = block.timestamp + time;
//         // _lockTime = now + time; "now" has been deprecated. Use "block.timestamp" instead.
//         emit OwnershipTransferred(_owner, address(0));
//     }
    
//     //Unlocks the contract for owner when _lockTime is exceeds
//     function unlock() public virtual {
//         require(_previousOwner == msg.sender, "You don't have permission to unlock");
//         require(block.timestamp > _lockTime , "Contract is locked until 7 days");
//         //  require(now> _lockTime , "Contract is locked until 7 days"); "now" has been deprecated. Use "block.timestamp" instead.
//         emit OwnershipTransferred(_owner, _previousOwner);
//         _owner = _previousOwner;
//     }
// }
