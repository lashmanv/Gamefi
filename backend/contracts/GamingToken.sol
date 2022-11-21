// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 0x5b7879adb5297db6f1d7cfd57c317229c136825f2ea2575d976b472fff662f7b

import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import "./ERC/ERC20.sol";

contract GamingToken is ChainlinkClient, ConfirmedOwner, ERC20 {

    using Strings for uint256;
    using Chainlink for Chainlink.Request;

    struct StakeStruct {
        uint256 NftId;
        uint256 timeStamp;
        bool stakeStatus;
    }

    IERC20 chainlink = IERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);

    mapping(uint256 => StakeStruct) private nftStake;

    mapping(uint256 => uint256) private nftBalance;

    mapping(bytes32 => bool) private requestResults;

    mapping(address => uint) private userRequests;

    mapping(address => uint256) private requestTime;

    uint256[] private _stakedNfts;

    uint256 public tokensPerMin;

    uint256 public welcomeAmount;

    uint256 public requestFee;

    uint256 constant ORACLE_PAYMENT = ((1 * LINK_DIVISIBILITY) / 100) * 5;

    string baseUrl = "https://us-central1-verifyowner-2eb61.cloudfunctions.net/test/";
    
    string constant jobId = "c1c5e92880894eb6b27d3cae19670aa3"; //MUMBAI
    
    constructor(
        uint256 _requestFee, uint256 _welcomeAmount, uint256 _tokensPerMin
        ) ERC20("Gaming Token", "GT") ConfirmedOwner(msg.sender) {
        // MUMBAI
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
    
        requestFee = _requestFee;
        tokensPerMin = _tokensPerMin;
        welcomeAmount = _welcomeAmount;
    }



    // https://us-central1-verifyowner-2eb61.cloudfunctions.net/test/0/0x3be242B8BbabDDadcD8be083C925FC7A69369ca7

    function stringToBytes32(string memory source) private pure returns (bytes32 result){
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }    



    function compareToIgnoreCase(string memory _base, string memory _value) private pure returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }



    function checkOwnership(uint256 _nftId,string memory _user) public payable returns (uint) {
        address user = _msgSender();
        require(msg.value >= requestFee, "Less fee amount transferred");

        require(user != address(0), "Invalid address");

        string memory _to = Strings.toHexString(user);

        bool isSame = compareToIgnoreCase(_user,_to);

        require(isSame, "Invalid user");

        if(requestTime[user] != 0) {
            require((block.timestamp - requestTime[user]) >= 300, "Try after some time");
        }

        string memory url = string(abi.encodePacked(baseUrl, _nftId.toString(), '/', _user));
 
        uint requestId = uint(submitRequest(url));

        userRequests[user] = requestId;

        requestTime[user] = block.timestamp;

        return requestId;
    }

    function submitRequest(string memory url) private returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(jobId), address(this), this.fulfillRequest.selector);
        
        // Set the URL to perform the GET request on
        req.add("get", url);
        req.add("path", "status");
                
        // Sends the request
        return sendChainlinkRequest(req, ORACLE_PAYMENT);
    }

    function fulfillRequest(bytes32 _requestId, bool _value) public recordChainlinkFulfillment(_requestId) {
        //require(tx.origin == address(this), "You're not the owner contract");
        emit RequestValue(_requestId, _value);

        requestResults[_requestId] = _value;
    }



    function stakeorUnstakeNft(uint256 _nftId, bool _stakeStatus) external {
        address user = _msgSender();
        require(user != address(0), "Invalid address");
        
        // require api (owner)

        // run own aws oracle // 3000/m - fee 10/req 

        // 3 mins stake/with2

        require(block.timestamp - requestTime[user] <= 60, "Request expired, Try again");

        bool isOwner = requestResults[bytes32(userRequests[user])];

        require(isOwner == true, "User is not the NFT owner");

        userRequests[user] = 0;
        requestTime[user] = 0;

        StakeStruct memory Stake = nftStake[_nftId];
        
            if(_stakeStatus){
                require(Stake.stakeStatus == false, "Nft already staked");

                nftStake[_nftId].NftId = _nftId;
                nftStake[_nftId].timeStamp = block.timestamp;           
                nftStake[_nftId].stakeStatus = _stakeStatus;

                _stakedNfts.push(_nftId);

                _mint(user, welcomeAmount * 10**uint(decimals()));
            }
            else{
                require(Stake.stakeStatus, "Nft not staked");

                uint256 tempBalance = (block.timestamp - Stake.timeStamp) / 60 ;

                tempBalance = tempBalance * tokensPerMin;

                tempBalance = tempBalance + nftBalance[_nftId];
                
                uint256[] storage tempArr = _stakedNfts;

                for(uint256 i = 0; i < tempArr.length; i++) {
                    if(tempArr.length > 1 && tempArr[i] == _nftId) {
                        for(uint256 j = i; j < tempArr.length; j++) {
                            tempArr[j] = tempArr[j+1];
                        }
                    }
                }

                tempArr.pop();

                _stakedNfts = tempArr;

                nftStake[_nftId].stakeStatus = false;

                _mint(user, tempBalance * 10**uint(decimals()));
            }

        emit status(_nftId,user,block.timestamp,_stakeStatus);
    }



    function withDrawBalance(uint256 _nftId, uint256 _amount) public {
        address user = _msgSender();
        require(user != address(0), "Invalid address");

        // require api (owner)
        require(block.timestamp - requestTime[user] <= 60, "Request expired, Try again");

        bool isOwner = requestResults[bytes32(userRequests[user])];

        require(isOwner == true, "User is not the NFT owner");

        require(isOwner, "User is not the NFT owner");

        userRequests[user] = 0;
        requestTime[user] = 0;

        uint256 tempBalance;

        StakeStruct memory Stake = nftStake[_nftId];

        require(Stake.timeStamp != 0, "Nft not staked");

        tempBalance = (block.timestamp - Stake.timeStamp) / 60 ;

        tempBalance = tempBalance * tokensPerMin;

        tempBalance = tempBalance + nftBalance[_nftId];

        require(_amount <= tempBalance, "Insufficient balance");

        require(_amount > 0, "Amount can't be zero");

        nftStake[_nftId].timeStamp = block.timestamp;

        nftBalance[_nftId] = tempBalance - _amount;

        _mint(user, _amount * 10**uint(decimals()));
    }

    

    function NftBalances(uint256[] memory _nftIds) public view returns (uint256) {
        address user = _msgSender();
        require(user != address(0), "Invalid address");

        uint256[] memory tempArr = _nftIds;

        uint256 balance = 0;

        bool valid;

        for(uint256 i = 0; i < tempArr.length; i++) {
            StakeStruct memory Stake = nftStake[tempArr[i]];

            if(Stake.timeStamp == 0) {
                valid = true;
            }
        }

        require(valid == false, "one or more Nfts not staked");

        for(uint256 i = 0; i < tempArr.length; i++) {

            StakeStruct memory Stake = nftStake[tempArr[i]];
    
            uint256 tempBalance = (block.timestamp - Stake.timeStamp) / 60 ;

            tempBalance = tempBalance * tokensPerMin;

            balance = tempBalance + nftBalance[tempArr[i]];
        }

        return balance;
    }



    function viewBalance(uint256 _nftId) public view returns(uint256) {
        address user = _msgSender();
        require(user != address(0), "Invalid address");

        StakeStruct memory Stake = nftStake[_nftId];

        require(Stake.timeStamp != 0, "Nft not staked");

        uint256 tempBalance = (block.timestamp - Stake.timeStamp) / 60 ;

        tempBalance = tempBalance * tokensPerMin;

        tempBalance = tempBalance + nftBalance[_nftId];

        return tempBalance;
    }



    function stakedNfts() external onlyOwner view returns(uint256[] memory) {
        return (_stakedNfts);
    }



    function time() public view returns(uint256) {
        return block.timestamp;
    }



    function getRequestResult() public view returns (bool) {
        require(_msgSender() != address(0), "Invalid address");
        require(block.timestamp - requestTime[_msgSender()] <= 60, "Request expired, Try again");

        return requestResults[bytes32(userRequests[_msgSender()])];
    }

    function getRequestTime() public view returns (uint256) {
        require(_msgSender() != address(0), "Invalid address");

        return requestTime[_msgSender()];
    }

    function withdrawMatic() external onlyOwner() {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawChainlink() external onlyOwner() {
        chainlink.transfer(msg.sender,chainlink.balanceOf(address(this)));
    }



    event RequestValue(bytes32 indexed requestId, bool indexed value);

    
    event status(uint256 _nftId, address user, uint256 timestamp, bool stakeOrUnstake);
    
}

//contract : 