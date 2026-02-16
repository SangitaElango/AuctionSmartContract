// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract auctionContract {
    address payable public owner;
    string public ipfshash;
    
    uint public auctionStartBlock;
    uint public auctionEndBlock;
    enum State { Started, Running, Ended, cancelled }
    State public auctionState;

    address payable public highestBidder;
    uint public highestBindingBid;

    mapping (address => uint) public bids;
    uint bidIncreament;

    constructor(address payable contractOwner){
        owner = contractOwner;
        ipfshash = "";
        auctionState = State.Running;
        auctionStartBlock = block.number;
        auctionEndBlock = block.number + 30432;
        bidIncreament = 100;
    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier auctionAlive(){
        require(block.number>=auctionStartBlock && block.number<=auctionEndBlock);
        _;
    }

    function min(uint a, uint b) public pure returns(uint){
        if(a<=b) {
            return a;
        }
        else{
            return b;
        }
    }

    function placeBid() public payable notOwner auctionAlive{
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = msg.value + bids[msg.sender];
        require(currentBid >= highestBindingBid);
        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid+bidIncreament, bids[highestBidder]);
        }
        else{
            highestBindingBid = min(bids[highestBidder]+bidIncreament, currentBid);
            highestBidder = payable(msg.sender);
        }
        
    }

    function cancelAuction() public onlyOwner auctionAlive{
        require(auctionState == State.Running);
        auctionState = State.cancelled;
    }

    function finalizeAuction() public{
        require(auctionState == State.cancelled || auctionState == State.Ended);
        require(msg.sender == owner || block.number >= auctionEndBlock);

        address payable recipient;
        uint value;

        recipient = payable(msg.sender);

        if(auctionState == State.cancelled){
            
            value = bids[msg.sender];
        }
        else{
            if(msg.sender == owner){
                value = highestBindingBid;
            }
            else{
                if(msg.sender == highestBidder){
                    value = bids[highestBidder] - highestBindingBid;
                }
                else{
                    value = bids[msg.sender];
                }
            }
        }

        bids[recipient] = 0;

        recipient.transfer(value);
    }
}

contract auctionContractCreator{
    address public owner;
    auctionContract[] public auctions;

    constructor(){
        owner = msg.sender;
    }

    function deployAuction() public{
        auctionContract auction = new auctionContract(payable (msg.sender));
        auctions.push(auction);
    }
}

