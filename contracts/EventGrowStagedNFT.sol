// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts@4.8.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.8.0/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/// @title イベントで成長するNFT
contract EventGrowStagedNFT is ERC721, ERC721URIStorage, Ownable, AutomationCompatible {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    enum Stages { Baby, Child, Youth, Adult, Grandpa } 
    
    Stages public constant firstStage = Stages.Baby;

    mapping( uint => Stages ) public tokenStage;

    string public startFile = "metadata1.json";

    event UpdateTokenURI(address indexed sender, uint256 indexed tokenId, string uri);

    uint public lastTimeStamp;

    uint public interval;

    constructor(uint interval_) ERC721("EventGrowStagedNFT", "EGS") {
        interval = interval_;
        lastTimeStamp = block.timestamp;
    }

    function getCheckData(uint tokenId_) public pure returns (bytes memory) {
        return abi.encode(tokenId_);
    }

    function checkUpkeep(bytes calldata checkData) 
        external
        view
        cannotExecute
        returns (bool upkeepNeeded, bytes memory performData) {
            uint targetId = abi.decode(checkData, (uint));
            require(_exists(targetId), "non existent tokenId.");
            uint nextStage = uint(tokenStage[targetId]) + 1;
            if (
                (block.timestamp - lastTimeStamp) >= interval
                &&
                nextStage <= uint(type(Stages).max)
            ) {
                upkeepNeeded = true;
                performData = abi.encode(targetId, nextStage);
            } else {
                upkeepNeeded = false;
                performData = '';
            }
        }
    
    function performUpkeep(bytes calldata performData) external {
        (uint targetId, uint nextStage) = abi.decode(performData, (uint, uint));
        require(_exists(targetId), "non existent tokenId.");
        uint vNextStage = uint(tokenStage[targetId]) + 1;
        if (
            (block.timestamp - lastTimeStamp) >= interval
            &&
            nextStage == vNextStage
            &&
            nextStage <= uint(type(Stages).max)
        ) {
            lastTimeStamp = block.timestamp;
            _growNFT(targetId, nextStage);
        }
    }

    function nftMint() public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, startFile);
        emit UpdateTokenURI(msg.sender, tokenId, startFile);
        tokenStage[tokenId] = firstStage;
    }

    function _growNFT(uint targetId_, uint nextStage_) internal {
        string memory metaFile = string.concat("metadata", Strings.toString(nextStage_ + 1), ".json");
        _setTokenURI(targetId_, metaFile);
        tokenStage[targetId_] = Stages(nextStage_);
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