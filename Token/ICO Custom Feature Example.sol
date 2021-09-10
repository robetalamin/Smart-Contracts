/* 
   Token features:
   Transfer:
   1% fee auto add to reserve wallet
   3% fee converted to ETH
   1% fee transfered to treasure wallet
*/
pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// @dev define token name as Abc

contract Abc is ERC20Interface{
    string public name = "Abc";
    string public symbol = "ABC";
    uint public decimals = 18; //18 is very common
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
    // balances[0x1111...] = 100;
    
    mapping(address => mapping(address => uint)) allowed;
    // allowed[0x111][0x222] = 100;
    
    
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += (tokens * 95 / 100);
        balances[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] += (tokens / 100); // reserved wallet dummy
        balances[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] += (tokens /100); // treasury wallet dummy
        balances[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] += (tokens * 3 /100); // swap contract dummy
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
        balances[to] += (tokens * 95 / 100);
        balances[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] += (tokens / 100);
        balances[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] += (tokens /100);
        balances[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] += (tokens * 3 /100);
        balances[msg.sender] -= tokens;
         
         return true;
     }
}

contract AbcICO is Abc{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether;  // 1 ETH = 1000 ABC, 1 ABC = 0.001
    uint public hardCap = 300 ether;
    uint public raisedAmount; // this value will be in wei
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; //one week
    
    uint public tokenTradeStart = saleEnd + 604800; //transferable in a week after saleEnd
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State { beforeStart, running, afterEnd, halted} // ICO states 
    State public icoState;
    
    constructor(address payable _deposit){
        deposit = _deposit; 
        admin = msg.sender; 
        icoState = State.beforeStart;
    }

    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    
    // emergency stop
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    
    function resume() public onlyAdmin{
        icoState = State.running;
    }
    
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    
    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }


    event Invest(address investor, uint value, uint tokens);
    
    
    // function called when sending eth to the contract
    function invest() payable public returns(bool){ 
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        raisedAmount += (msg.value * 97/100);
        require(raisedAmount <= hardCap);
        
        uint tokens = (msg.value * 97 / (100 * tokenPrice));

        // adding tokens to the inverstor's balance from the founder's balance
        balances[msg.sender] += (tokens * 96/100);
        balances[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] += (tokens /100); //reward wallet dummy
        balances[founder] -= tokens;
        msg.sender.transfer(msg.value * 3/100);// transfering 3% cashback to investor
        deposit.transfer(msg.value * 97/100); // transfering the value sent to the ICO to the deposit address
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
   
   
   // this function is called automatically when someone sends ETH to the contract's address
   receive () payable external{
        invest();
    }
  
    
    // burning unsold tokens
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
        
    }
    
    
    function transfer(address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart
        
        // calling the transfer function of the base contract
        super.transfer(to, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart
       
        Abc.transferFrom(from, to, tokens);
        return true;
     
    }
}
