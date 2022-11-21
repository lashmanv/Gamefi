// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ERC/ERC721.sol";

// ipfs://QmcC8cvUD4PbZzxvbUYd9amPXyKeNFwzJwhvuyeTEVQQ6b

contract GamingNft is ERC721, Ownable, ReentrancyGuard{
    using Strings for uint256;

    IERC20 gamingToken = IERC20(0x37095837Be5e8C0F5d0244D5dD6dFd9Def399d48);

    struct AttributesStruct {
        uint256 Health;
        uint256 Power;
        uint256 Speed; 
        uint256 Regeneration; 
    }

    struct GameStruct {
        uint256 nftId;
        uint256 timeStamp;
    }

    struct RarityStruct {
        uint256 rarityPrice;
        uint256 maxRarityLimit;
        uint256 minRarityLimit;
        uint256 maxCharacterLimit;
        uint256 minCharacterLimit;
    }

    // mapping for nft URIs
    mapping(uint256 => string) private _tokenURI;

    mapping(uint256 => AttributesStruct) public _nftAttributes;

    mapping(uint256 => GameStruct) public _gameStatus;

    RarityStruct[4] public _rarities;

    string private baseURI;

    uint256 private currentIndex = 0;

    uint256 public nftPrice = 100 * 10 ** 18;

    uint256 maxMintlvl = 70;

    uint256 characters = 18;

    constructor(string memory _baseUri) ERC721("Gaming Nfts", "GNFTS") {
        baseURI = _baseUri;
    }

    

    function _setTokenURI(uint256 tokenId, string memory _tokenUri) private {
        _tokenURI[tokenId] = _tokenUri;
    }


   
    /**
    * Mint function
    * @param _to: address of receiver
    */
    function mintNft(address _to) external {    
        address user = _msgSender();
        require(user != address(0) || _to != address(0), "Invalid address");

        require(nftPrice <= gamingToken.balanceOf(user), "Insufficient balance");

        gamingToken.transferFrom(_to,address(this), nftPrice);

        uint256[] memory arr = new uint[](5);

        for(uint256 i = 0; i < 5; i++) {
            uint256 randomNum = uint256(keccak256(abi.encode(_to,tx.gasprice + i,block.number,block.timestamp + i,block.difficulty,address(this))));

            arr[i] = randomNum % maxMintlvl ;
        }

            arr[4] = arr[4] % (18 - 9 + 1) + 9;
        
        _nftAttributes[currentIndex].Health = arr[0];
        _nftAttributes[currentIndex].Power = arr[1];
        _nftAttributes[currentIndex].Speed = arr[2];
        _nftAttributes[currentIndex].Regeneration = arr[3];
 
        _tokenURI[currentIndex] = string(abi.encodePacked(baseURI,"/", arr[4].toString(),".json"));

        uint256 supply = currentIndex;
        
        _safeMint(_to, supply);
        
        currentIndex = supply + 1;
    }

    /**
    * Mystery NFT Mint function
    * @param _to: address of receiver
    */
    function mysteryBox(address _to, uint256 _amount) external {    
        address user = _msgSender();
        require(user != address(0) || _to != address(0), "Invalid address");

        // require(_rarities[3].rarityPrice <= _amount, "Invalid amount");
        // require(_rarities[3].rarityPrice <= gamingToken.balanceOf(user), "Insufficient balance");

        // gamingToken.transferFrom(_to,address(this), _amount);

        uint256 lvl;

        if(_amount >= _rarities[1].rarityPrice){
            lvl = 1;
        }
        else if(_amount >= _rarities[2].rarityPrice) {
            lvl = 2;
        }
        else if(_amount >= _rarities[3].rarityPrice) {
            lvl = 3;
        }

        RarityStruct memory rarity = _rarities[lvl];

        uint256[] memory arr = new uint[](5);

        for(uint256 i = 0; i < 4; i++) {
            uint256 randomNum = uint256(keccak256(abi.encode(_to,tx.gasprice + i,block.number,block.timestamp + i,block.difficulty,address(this))));

            arr[i] = randomNum % (rarity.maxRarityLimit - rarity.minRarityLimit + 1) + rarity.maxRarityLimit;
        }

        if(_amount >= _rarities[1].rarityPrice) {
            arr[4] = uint256(keccak256(abi.encode(_to,tx.gasprice + arr[3],block.number,block.timestamp + arr[3],block.difficulty,address(this))));

            arr[4] = arr[4] % (3 - 1 + 1) + 1;
        }
        else{
            arr[4] = uint256(keccak256(abi.encode(_to,tx.gasprice + arr[3],block.number,block.timestamp + arr[3],block.difficulty,address(this))));

            arr[4] = arr[4] % (rarity.maxCharacterLimit - rarity.minCharacterLimit + 1) + rarity.maxCharacterLimit;
        }
        
        _nftAttributes[currentIndex].Health = arr[0];
        _nftAttributes[currentIndex].Power = arr[1];
        _nftAttributes[currentIndex].Speed = arr[2];
        _nftAttributes[currentIndex].Regeneration = arr[3];
 
        _tokenURI[currentIndex] = string(abi.encodePacked(baseURI,"/", arr[4].toString(),".json"));

        uint256 supply = currentIndex;
        
        _safeMint(_to, supply);
        
        currentIndex = supply + 1;
    }

    

    function gameNftStatus(uint256 _nftId) public {
        require(_exists(_nftId), "Token nonexists");

        _gameStatus[_nftId].nftId = _nftId;
        _gameStatus[_nftId].timeStamp = block.timestamp;
    }



    function setMintPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Invalid price");

        nftPrice = _newPrice;

        emit rarityPrice(0,_newPrice);
    }

    function setMysteryBoxPrice(uint256 _raritylvl, uint256 _newPrice) external onlyOwner {
        require(_raritylvl != 0 && _raritylvl < 4, "Invalid rarity");
        require(_newPrice > 0, "Invalid price");

            _rarities[_raritylvl].rarityPrice = _newPrice;

        emit rarityPrice(_raritylvl,_newPrice);
    }

    function setRarityLimits(uint256 _raritylvl, uint256 _maxLimit, uint256 _minLimit) external onlyOwner {
        require(_raritylvl != 0 && _raritylvl < 4, "Invalid rarity");
        require(_maxLimit > 0 && _minLimit > 0, "Invalid limit");

        
        _rarities[_raritylvl].maxRarityLimit = _maxLimit;
        _rarities[_raritylvl].minRarityLimit = _minLimit;

        emit rarityLimit(_raritylvl,_maxLimit,_minLimit);
    }

    function setCharacterLimits(uint256 _raritylvl, uint256 _maxLimit, uint256 _minLimit) external onlyOwner {
        require(_raritylvl != 0 && _raritylvl < 4, "Invalid rarity");
        require(_maxLimit > 0 && _minLimit > 0, "Invalid limit");

        
        _rarities[_raritylvl].maxCharacterLimit = _maxLimit;
        _rarities[_raritylvl].minCharacterLimit = _minLimit;

        emit rarityLimit(_raritylvl,_maxLimit,_minLimit);
    }



    function totalSupply() public view returns (uint256) {
        return currentIndex;
    }



    function tokenURI(uint256 _nftId) public view override returns (string memory) {
        require(_exists(_nftId), "Token nonexists");
        require(ownerOf(_nftId) != address(0), "Token nonexists");

        return _tokenURI[_nftId];
    }



    function withdrawGamingToken() external onlyOwner() {
        (bool success, ) = msg.sender.call{value: gamingToken.balanceOf(address(this))}("");
        require(success, "Transfer failed.");
    }



    //withdraw to owner wallet
    function withdrawMatic() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    

    
    function set(uint256 _raritylvl, uint256 newPrice,uint256 maxRLimit,uint256 minRLimit,uint256 _maxCLimit,uint256 _minCLimit) external onlyOwner {
        _rarities[_raritylvl].rarityPrice = newPrice;
        _rarities[_raritylvl].maxRarityLimit = maxRLimit;
        _rarities[_raritylvl].minRarityLimit = minRLimit;
        _rarities[_raritylvl].maxCharacterLimit = _maxCLimit;
        _rarities[_raritylvl].minCharacterLimit = _minCLimit;
    }



    event rarityPrice(uint256 _raritylvl,uint256 _price);

    event rarityLimit(uint256 _raritylvl, uint256 _maxLimit, uint256 _minLimit);
}