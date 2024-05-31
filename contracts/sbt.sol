// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Soulbound is ERC721, ERC721URIStorage, Ownable {

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
    uint256 mintRate = 10000000000000000;
    string private _baseURIextended;

   
    constructor() ERC721("Subscription to Mazh's Newsletter", "MAZH") {}

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setTokenAuth(uint256 _tokenId, address _burnauthadd) internal {
        authorization[_tokenId][_burnauthadd] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        require((from == address(0)) || (to == address(0)), "Token not transferable");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function safeMint(address to, uint256 tokenId, string memory uri, BurnAuth _burnauth) payable public onlyOwner {
        require(msg.value == mintRate, "Not enough eth sent.");
        _tokenIdCounter += 1;
        _safeMint(to, _tokenIdCounter);
        _setTokenURI(tokenId, uri);
        if(_burnauth == BurnAuth.IssuerOnly){
            setTokenAuth(tokenId, msg.sender);
        }else if(_burnauth == BurnAuth.OwnerOnly){
            setTokenAuth(tokenId, to);
        }else if(_burnauth == BurnAuth.Both){
            setTokenAuth(tokenId, msg.sender);
            setTokenAuth(tokenId, to);
        }else if(_burnauth == BurnAuth.Neither){
            setTokenAuth(tokenId, address(0));
        }
            
        emit Issued(msg.sender, to, tokenId, _burnauth);
    }

    function burnAuth(uint256 tokenId) external{
        _burn(tokenId);
       

    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(authorization[tokenId][msg.sender] == true);
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}