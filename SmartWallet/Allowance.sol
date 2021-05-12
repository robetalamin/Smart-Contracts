pragma solidity ^0.8.00;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Allowance {
    /*
    in solidity 0.8.00 overflow and underflow has been addressed by solidity compiler
    hence, using safemath library is not necessary if the contract is compiled using solidity version 0.8.00 or later
    */
    using SafeMath for uint;
    
    address public owner;
    
    constructor () {
        owner = msg.sender;
    }
    
    modifier onlyowner() {
        require(msg.sender == owner, "you are not allowed");
        _;
    }
    
    event AllowanceChanged(address indexed _ForWho, address indexed _By, uint _OldAmount, uint _NewAmount);
    
    mapping(address => uint) public allowance;
    
    function SetAllowance(address _who, uint _amount) public onlyowner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    modifier onlyowner1(uint _amount) {
        require(msg.sender == owner || allowance[msg.sender] >= _amount, "you are not allowed");
        _;
    }
    
    function RedAllowance(address _who, uint _amount) internal {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who].sub(_amount));
        allowance[_who] = allowance[_who].sub(_amount);
    }
}
