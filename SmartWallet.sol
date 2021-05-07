pragma solidity ^0.8.00;

import "./Allowance.sol";

contract SmartWallet is Allowance {
    
    event MoneySent(address indexed _to, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    function withdrawMoney(address payable _to, uint _amount) public onlyowner1(_amount){
        emit MoneySent(_to, _amount);
        require(address(this).balance >= _amount, "not enough funds");
        if (msg.sender != owner) {
            RedAllowance(msg.sender, _amount);
        }
            _to.transfer(_amount);
        
    }
    
    function WalletBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
        
    }
}
