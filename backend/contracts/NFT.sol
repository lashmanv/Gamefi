// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// ipfs://QmZvcBbTZXT2KPDNa8oWj2gaHaEmExvvrvKeeR1o7p7juL
// 0xf83ff10f25537121816d927e17f79370c3281c4dcb708e47142b3bc0dc41e916

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Auction.sol";
import "./ERC721.sol";

contract Nft is ERC721, Auction, ReentrancyGuard{
    using Strings for uint256;

    string private baseURI;

    // Minting rules and supplies
    uint256 public immutable MAX_SUPPLY = 50;

    uint256 public MINTING_PRICE = 0.001 ether;
    uint256 public MAX_WHITELIST_MINT = 1;
    uint256 public MAX_SECONDARY_MINT = 1;

    uint256 private auctionLimit = 25;

    uint256 private auctionIndex = 0;
    
    uint256 private currentIndex = 0;

    uint256 private preSaleTokens = 25;
    
    
    bool public saleStatus;

    bytes32 private publicMerkleRoot;

    bytes32 private secondaryMerkleRoot;


    // mapping to check the users mint count
    mapping(address => uint256) public mintCount; 

    // mapping for nft URIs
    mapping(uint256 => string) private _tokenURIs;

    // mapping for nft hold
    mapping(uint256 => uint256) private nftHold;

    // mapping for available uris
    mapping(uint => uint) private _availableTokens;


    constructor(string memory baseUri,bytes32 _publicMerkleRoot) ERC721("Nfts", "NFTS") {
        baseURI = baseUri;
        publicMerkleRoot = _publicMerkleRoot;
    }

    function mint() public {
        _mint(_msgSender(),currentIndex++);
    }

    function testUri() public view returns (string[] memory) {

        string[] memory arr = new string[](50);
        
        for(uint256 i = 0; i < 50; i++) {
            arr[i] = _tokenURIs[i];
        }
        return arr;
    }
    
    function totalSupply() external view returns (uint256) {
        return currentIndex;
    }

    /**
    * Define merkle root
    * @param newMerkleRoot: newly defined merkle root
    */
    function changePublicMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        publicMerkleRoot = newMerkleRoot;
    }

    /**
    * Define merkle root
    * @param newMerkleRoot: newly defined merkle root
    */
    function changeSecondaryMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        secondaryMerkleRoot = newMerkleRoot;
    }

    

    /**
    * Set sale status
    */
    function changeSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }



    /**
    * check whitelist
    * @param merkleProof: series of merkle hashes to prove whitelist
    * @param leaf: hash of user address
    */
    function isWhitelisted(bytes32[] calldata merkleProof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(merkleProof, publicMerkleRoot, leaf);
    }

    /**
    * check whitelist
    * @param merkleProof: series of merkle hashes to prove whitelist
    * @param leaf: hash of user address
    */
    function isSecondaryWhitelisted(bytes32[] calldata merkleProof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(merkleProof, secondaryMerkleRoot, leaf);
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) private {
        _tokenURIs[tokenId] = _tokenURI;
    }
    


    
    function getRandomAvailableTokenId(address to, uint updatedNumAvailableTokens)
        private
        returns (uint256)
    {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle. Code taken from CryptoPhunksV2
    function getAvailableTokenAtIndex(uint256 indexToUse, uint numAvailableTokens)
        private
        returns (uint256)
    {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = numAvailableTokens - 1;
        if (indexToUse != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[indexToUse] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[indexToUse] = lastValInArray;
                // Gas refund courtsey of @dievardump
                delete _availableTokens[lastIndex];
            }
        }
        
        return result;
    }
    

        
    /**
    * Auction Mint function
    * @param to: address of receiver
    */
    function auctionMint(address to) external onlyOwner {        
        require(currentIndex < MAX_SUPPLY, "Maximum supply exceeds"); 
        require(auctionIndex < auctionLimit, "Auction limit exceeds"); 

        uint256 rand = getRandomAvailableTokenId(to, (MAX_SUPPLY - currentIndex));

        _setTokenURI(currentIndex,string(abi.encodePacked(baseURI,"/", rand.toString(),".json")));

        nftHold[currentIndex] = block.timestamp;

        _mint(to,currentIndex);

        currentIndex++;

        auctionIndex++;
    }

    /**
    * Mint function
    * @param merkleProof: series of merkle hashes to prove whitelist
    */
    function whitelistMint(bytes32[] calldata merkleProof,address to) external payable nonReentrant{
        address user = _msgSender();

        uint256 count = mintCount[user];

        require(saleStatus, "Sale has not begun yet");
        require(isWhitelisted(merkleProof, keccak256(abi.encodePacked(user))), "User not  Whitelisted");
        require(msg.value == MINTING_PRICE, "Invalid Amount");
        require(count < MAX_WHITELIST_MINT, "Max Whitelist Allocation limit exceeds");
        require(currentIndex < preSaleTokens, "Maximum supply exceeds"); 

        uint256 rand = getRandomAvailableTokenId(to, (MAX_SUPPLY - currentIndex));

        _setTokenURI(currentIndex,string(abi.encodePacked(baseURI,"/", rand.toString(),".json")));

        nftHold[currentIndex] = block.timestamp;

        mintCount[user] = count + 1;

        _mint(to,currentIndex);

        currentIndex++;
    }

    /**
    * Mint function
    // 0x5b7879adb5297db6f1d7cfd57c317229c136825f2ea2575d976b472fff662f7b
    * @param merkleProof: series of merkle hashes to prove whitelist
    */
    function secondaryMint(bytes32[] calldata merkleProof,address to) external payable nonReentrant{
        address user = _msgSender();

        uint256 count = mintCount[user];

        require(saleStatus, "Sale has not begun yet");        
        require(isSecondaryWhitelisted(merkleProof, keccak256(abi.encodePacked(user))), "User not  Whitelisted");
        require(msg.value == MINTING_PRICE, "Invalid Amount");
        require(count < MAX_SECONDARY_MINT, "Max Allocation limit exceeds");
        require(currentIndex >= preSaleTokens, "Secondary sale not started"); 
        require(currentIndex < MAX_SUPPLY, "Maximum supply exceeds"); 

        uint256 rand = getRandomAvailableTokenId(to, (MAX_SUPPLY - currentIndex));

        _setTokenURI(currentIndex,string(abi.encodePacked(baseURI,"/", rand.toString(),".json")));

        nftHold[currentIndex] = block.timestamp;

        mintCount[user] = count + 1;

        _mint(to, currentIndex);

        currentIndex++;
    }


    // this function is used to transfer the Tokens from the tokenholder
    function safeTransferFrom(address from,address to,uint256 _tokenId) public virtual override {
        require(from != address(0), "Invalid address");
        require(to != address(0) && to != from, "Invalid address");
        require(_exists(_tokenId), "Token nonexists");
        
        nftHold[_tokenId] = block.timestamp;

        super.safeTransferFrom(from,to,_tokenId);
    }

    // this function is used to transfer the Tokens from the tokenholder
    function safeTransferFrom(address from,address to,uint256 _tokenId, bytes memory data) public virtual override {
        require(from != address(0), "Invalid address");
        require(to != address(0) && to != from, "Invalid address");
        require(_exists(_tokenId), "Token nonexists");
        
        nftHold[_tokenId] = block.timestamp;

        super.safeTransferFrom(from,to,_tokenId,data);
    }

    // admin transfer require != admin
    function auctionTransfer(uint256 _nftId,address to) external onlyOwner {
        AuctionStruct memory auction = nftAuction[_nftId];
        require(auction.auctionDuration < block.timestamp, "Auction not yet ended.");

        require(isClaimed[_nftId][to] == true, "Winner not yet transferred the bid amount");

        nftHold[_nftId] = block.timestamp;

        safeTransferFrom(_msgSender(),to,_nftId);
    }

    function updateUserMintCount(address user) external {
        require(user != address(0), "zero address");
        mintCount[user] = 0 ;
    }

    function nftHoldings(uint256 nftId) public view returns(uint256,address,uint256,string memory) {
        require(_exists(nftId), "Token nonexists");

        address holder = ownerOf(nftId);
        uint256 time = nftHold[nftId];
        string memory uri = _tokenURIs[nftId];

        return (nftId,holder,time,uri);
    }

    /**
    * Set the minting price
    * @param mintingPrice: new minting price
    */
    function setMintingPrice(uint256 mintingPrice) external onlyOwner {
        MINTING_PRICE = mintingPrice;
    }

    /**
    * Set the max secondary mint limit
    * @param maxSecondaryMint: new public mint limit
    */
    function setMaxSecondaryMint(uint256 maxSecondaryMint) external onlyOwner {
        MAX_SECONDARY_MINT = maxSecondaryMint;
    }

    /**
    * Set the max whitelist mint limit
    * @param maxWhitelistMint: new whitelist mint limit
    */
    function setMaxWhitelistMint(uint256 maxWhitelistMint) external onlyOwner {
        MAX_WHITELIST_MINT = maxWhitelistMint;
    }


    /**
    * Set the token URI
    * @param nftId: token Id
    * @param nftURI: new token URI
    */
    function setTokenURI(uint256 nftId,string memory nftURI) external onlyOwner {
        require(bytes(nftURI).length != 0 ,"Invalid Uri");

        _setTokenURI(nftId,nftURI);
    }



    /**
    * Get the URI of a selected token
    * @param nftId: token id from which to get token URI
    */
    function tokenURI(uint256 nftId) public view override returns (string memory) {
        require(_exists(nftId), "Token nonexists");

        if (saleStatus == true) {            
            return _tokenURIs[nftId];
        } else {
            return "ipfs://QmWfXXNi3WtxMtyw1AhiX7FFsxJeNPUzLMe5Cojyd86mXN";
        }
    }


    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721,AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
   
}


// ["0x6687769569d93b734160a7f1cb88f1f965080fb67b98631344b8c38426cff5b6","0x664de701e1d7cefce2e1cb54e69fedacf7322a1830b3d49b2417cf84bb083a62","0xb49abd4102a5911165e24fb8d9908fce24f2d68b3b60a8b381f5c9b7bda9d7b8","0x6ca1d5505de9622c46f6a55e22e1b45ea538c46a8b1d8e98237d43dbcd330bfb"]