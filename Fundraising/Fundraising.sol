pragma solidity ^0.8.0;

contract FundRaising{
    //contributors to the FundRaising Campaign
    mapping(address => uint) public contributors;
    
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline; //this is a timestamp (seconds)
    //amount that must be raised for a successful Campaign
    uint public goal;
    uint public raisedAmount = 0;
    address payable recipient;
    
    //Spending Request created by admin, must be voted by donors
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }
    
    uint index;
    mapping(uint=>Request) requests;
    
    event contributeEvent(address sender, uint value);
    event createRequestEvent(string _description, address _recipient, uint _value);
    event makePaymentEvent(address recipient, uint value);
    event refundEvent(address _recipient, uint _value);
    event voteRequestEvent(uint _index, address _voter);

    
    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        
        admin = msg.sender;
        minimumContribution = 10;
    }
    
   
   
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
   
   
    function contribute() public payable{
        require(block.timestamp < deadline);
        require(msg.value >= minimumContribution);
        
        if(contributors[msg.sender] == 0){
            noOfContributors++;
        }
        
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        emit contributeEvent(msg.sender, msg.value);
        
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    //refund if goal not met within deadline
    function getRefund() public{
        require(block.timestamp > deadline);
        require(raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        
        recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        
        recipient.transfer(value);
        contributors[msg.sender] = 0;
        
        emit refundEvent(msg.sender, value);
        
    }
    
    
    //admin creates spending request
        function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[index];
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
        
        index++;
        
        emit createRequestEvent (_description, _recipient, _value);
    }
    
    
    

    //contributors vote for a request
  function voteRequest(uint _index) public{
      Request storage thisRequest = requests[_index];
    
      require(contributors[msg.sender] > 0);
      require(thisRequest.voters[msg.sender] == false);
      
      thisRequest.voters[msg.sender] = true;
      thisRequest.noOfVoters++;
      
      emit voteRequestEvent(_index, msg.sender);
      
  }
    
    //if voted, owner sends money to the recipient (vendor, seller)
    function makePayment(uint _index) public onlyAdmin{
        Request storage thisRequest  = requests[_index];
        require(thisRequest.completed == false);
        
        require(thisRequest.noOfVoters > noOfContributors / 2);//more than 50% voted
        thisRequest.recipient.transfer(thisRequest.value); //trasfer the money to the recipient
        
        thisRequest.completed = true;
        emit makePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
    
    
}

