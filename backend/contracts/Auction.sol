// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is AccessControl,Ownable {

    struct AuctionStruct {
        uint256 NftId;
        uint256 NftPrice;
        uint256 maximumBids;
        uint256 totalBids;
        uint256 auctionStartTime;
        uint256 auctionDuration;
        uint256[] nftBidAmount;
        address[] nftBidders;
        uint256 highestBid;
        address highestBidder;
        bool auctionStatus;
    }

    mapping(uint256 => AuctionStruct) public nftAuction;

    mapping(uint256 => mapping(address => bool)) private userBids;

    mapping(uint256 => mapping(address => bool)) public isClaimed;


    function createNewAuction(uint256 _nftId,uint256 _nftPrice, uint256 _maxBids) external onlyOwner {
        uint256 isCreated = nftAuction[_nftId].auctionDuration;
        require(isCreated < block.timestamp, "Nft already listed for auction" );

        nftAuction[_nftId].NftId = _nftId;
        nftAuction[_nftId].NftPrice = _nftPrice;
        nftAuction[_nftId].maximumBids = _maxBids;
        
        emit AuctionCreated(_nftId,_nftPrice,_maxBids);
    }

    function startAuction(uint256 _nftId,uint256 startInUnixTime,uint256 durationInSecs) external onlyOwner {
        uint256 isCreated = nftAuction[_nftId].auctionDuration;
        require(isCreated < block.timestamp, "Nft already listed for auction" );

        require(nftAuction[_nftId].NftPrice != 0, "Nft not set for auction.");
        require(startInUnixTime >= block.timestamp, "Invalid Time.");
        require(durationInSecs >= 8, "Invalid duration.");

        nftAuction[_nftId].auctionStartTime = startInUnixTime;
        nftAuction[_nftId].auctionDuration = block.timestamp + durationInSecs;
        nftAuction[_nftId].auctionStatus = true;

        emit AuctionStarted(_nftId,nftAuction[_nftId].auctionDuration,true);
    }

    function toggleAuction(uint256 _nftId) external onlyOwner {
        require(nftAuction[_nftId].auctionDuration > block.timestamp, "Invalid auction.");

        bool status = nftAuction[_nftId].auctionStatus;
        nftAuction[_nftId].auctionStatus = !status;

        emit AuctionStarted(_nftId,nftAuction[_nftId].auctionDuration,false);
    }

    function makeABid(uint256 _nftId, uint256 bidAmount) external {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        AuctionStruct memory Nft = nftAuction[_nftId];
        bool isBidded = userBids[_nftId][user];

        require(bidAmount >= Nft.NftPrice, "Bid Amount is low.");        
        require(Nft.auctionDuration >= block.timestamp, "Auction ended.");
        require(Nft.auctionStatus == true, "Auction paused.");
        require(Nft.totalBids <= Nft.maximumBids, "Maximum bids made.");
        require(isBidded == false, "User already made a bid");

        userBids[_nftId][user] = true;

        nftAuction[_nftId].totalBids += 1;
        
        nftAuction[_nftId].nftBidAmount.push(bidAmount);
        nftAuction[_nftId].nftBidders.push(user);

        emit bidMade(_nftId,bidAmount);
    }

    function highestBid(uint256 _nftId) external onlyOwner returns(address,uint256){
        AuctionStruct memory Nft = nftAuction[_nftId];
        require(Nft.auctionStatus == false, "Auction is active.");
        require(Nft.auctionDuration < block.timestamp, "Auction not yet ended.");

        uint256[] memory arry =  nftAuction[_nftId].nftBidAmount;
        address[] memory biddersArry =  nftAuction[_nftId].nftBidders;

        uint256 max;
        uint256 index;

        for(uint256 i = 0 ; i < arry.length; i++) {
            if(arry[i] > max){
                max = arry[i];
                index = i;
            }
        }        

        address winner = biddersArry[index];

        nftAuction[_nftId].highestBid = max;
        nftAuction[_nftId].highestBidder = winner;

        return (winner,max);
    }

    function transferBidAmount(uint256 _nftId) public payable {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        address winner = nftAuction[_nftId].highestBidder;
        uint256 amount = nftAuction[_nftId].highestBid;

        require(user == winner, "User is not the Auction winner");
        require(msg.value == amount,"Invalid Amount");

        isClaimed[_nftId][user] = true;

        emit bidAmountTransfer(_nftId,amount);
    }

    event AuctionCreated(uint256 NftId, uint256 NftPrice, uint256 maxBids);

    event AuctionStarted(uint256 NftId, uint256 duration, bool auctionStatus);

    event bidMade(uint256 NftId, uint256 amount);

    event bidAmountTransfer(uint256 NftId, uint256 amount);
}
