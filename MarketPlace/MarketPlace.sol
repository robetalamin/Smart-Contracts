pragma solidity ^0.8.00;

contract Ownable {
    address public _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "you are not the owner");
        _;
    }
    
    function isOwner() public view returns(bool) {
        return(msg.sender == _owner);
    }
}

contract Item {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;
    
    ItemManager parentContract;
    
    constructor(ItemManager _parentContract, uint _priceInWei, uint _index) {
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _parentContract;
    }
    receive() external payable {
        require (priceInWei == msg.value, "only full payment is accepted");
        require (pricePaid == 0, "item is already paid");
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("addPayment(uint256)", index));
        require(success, "Transaction wasn't successful, cancelling");
    
    }
    
    fallback() external {
        
    }
}

contract ItemManager is Ownable {
    
    enum itemState{Added, Paid, Delivered}
    
    struct P_Item {
        Item _item;
        string _description;
        uint _itemPrice;
        ItemManager.itemState _state;
    }
    
    mapping (uint => P_Item) public items;
    uint itemIndex;
    
    event ItemStatus(uint _itemIndex, uint _status, address _itemAddress);
    
    function addItem(string memory _description, uint _itemPrice) public onlyOwner {
        Item item = new Item(this, _itemPrice, itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex]._description = _description;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = itemState.Added;

        emit ItemStatus(itemIndex, uint(items[itemIndex]._state), address (item));
        itemIndex++;
    
        
    }
    
    function addPayment(uint _itemIndex) public payable{
        require(items[_itemIndex]._itemPrice == msg.value, "only full payment accepted");
        require(items[_itemIndex]._state == itemState.Added, "item is already paid");
        items[_itemIndex]._state = itemState.Paid;
        emit ItemStatus(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
        
    }
    
    function startDelivery(uint _itemIndex) public onlyOwner {
        require(items[_itemIndex]._state == itemState.Paid, "you cant request for delivery");
        items[_itemIndex]._state = itemState.Delivered;
        
        emit ItemStatus(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }
}

    
    
