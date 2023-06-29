// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts@4.8.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.8.0/utils/Strings.sol";

/// @title 時間で成長するNFT
contract TimeGrowStagedNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    enum Stages { Baby, Child, Youth, Adult, Grandpa } 
    
    Stages public constant firstStage = Stages.Baby;

    mapping( uint => Stages ) public tokenStage;

    string public startFile = "metadata1.json";

    event UpdateTokenURI(address indexed sender, uint256 indexed tokenId, string uri);

    constructor() ERC721("TimeGrowStagedNFT", "TGS") {}

    function nftMint() public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, startFile);
        emit UpdateTokenURI(msg.sender, tokenId, startFile);
        tokenStage[tokenId] = firstStage;
    }

    function growNFT(uint targetId_) public {
        Stages curStage = tokenStage[targetId_];
        uint nextStage = uint(curStage) + 1;
        require (nextStage <= uint(type(Stages).max), "over stage");
        string memory metaFile = string.concat("metadata", Strings.toString(nextStage + 1), ".json");
        _setTokenURI(targetId_, metaFile);
        tokenStage[targetId_] = Stages(nextStage);
        emit UpdateTokenURI(msg.sender, targetId_, metaFile);
    }

    function _baseURI() internal pure override returns(string memory) {
        return "ipfs://bafybeichxrebqguwjqfyqurnwg5q7iarzi53p64gda74tgpg2uridnafva/";
    }

    /// @dev 以下は全てoverride 重複の整理
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}