// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Soulbound is ERC721, ERC721URIStorage, Ownable{
    enum BurnAuth {
        IssuerOnly,
        OwnerOnly,
        Both,
        Neither
    }

    event Issued (
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        BurnAuth burnAuth
    );

    mapping (uint256 => mapping (address => bool)) authorization;

    uint256 private _tokenIdCounter;
    uint256 public mintRate;
    string private _baseURIextended;
//mintrate 10000000000000000
    constructor(uint256 _mintRate, string memory _baseURI) ERC721("Subscription to Mazh's Newsletter", "MAZH") {
        mintRate = _mintRate;
        _baseURIextended = _baseURI;
    }

    //update base uri for token when created
    function updateBaseURI(string memory _baseURI) external onlyOwner() {
        _baseURIextended = _baseURI;
    }

    function updateMintRate(uint256 _newMintRate) external onlyOwner(){
        mintRate = _newMintRate;
    }

    //set TokenAuth type
    function setTokenAuth(uint256 _tokenId, address _burnauthadd) internal {
        authorization[_tokenId][_burnauthadd] = true;
    }


// can only be minted or burnt (from or to 0x00)
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId)
        internal
        override
    {
        require((_from == address(0)) || (_to == address(0)), "Token not transferable");
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
    

// Burn the SBT only who has access determined in mint 
// cacnea - remove onlyowner so everyone pays - check later how to lock the setTokenAuth value, not in hands of the user
    function safeMint(address _to, string memory _uri, BurnAuth _burnauth) payable public onlyOwner {
        require(msg.value == mintRate, "Not enough eth sent.");
        _tokenIdCounter += 1; //starts in 1
        _safeMint(_to, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, _uri);
        if(_burnauth == BurnAuth.IssuerOnly){
            setTokenAuth(_tokenIdCounter, msg.sender);
        }else if(_burnauth == BurnAuth.OwnerOnly){
            setTokenAuth(_tokenIdCounter, _to);
        }else if(_burnauth == BurnAuth.Both){
            setTokenAuth(_tokenIdCounter, msg.sender);
            setTokenAuth(_tokenIdCounter, _to);
        }else if(_burnauth == BurnAuth.Neither){
            setTokenAuth(_tokenIdCounter, address(0));
        }
            
        emit Issued(msg.sender, _to, _tokenIdCounter, _burnauth);
    }


    function burnAuth(uint256 _tokenId) external{
        _burn(_tokenId);
    }


    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        require(authorization[_tokenId][msg.sender] == true);
        super._burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

}