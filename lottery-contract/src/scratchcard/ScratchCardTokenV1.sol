// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ScratchCardPrize} from "./ScratchCardDef.sol";
import {IScratchCardToken} from "./interface/IScratchCardToken.sol";

contract ScratchCardTokenV1 is
    IScratchCardToken,
    ERC721,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable
{
    uint256 private _nextTokenId;

    mapping(ScratchCardPrize prize => string tokenUri) public prizeTokenUris;

    address allowedMinter;

    constructor() ERC721("ScratchCardToken", "SCR") Ownable(msg.sender) {
        // initialize prize token uris
        prizeTokenUris[
            ScratchCardPrize.GrandPrize
        ] = "ipfs/QmcEZLE5VLosTYtrim8rDfLfj3KkGRFUSisoihXo2LPJs4";
        prizeTokenUris[
            ScratchCardPrize.SmallPrize
        ] = "ipfs/QmZGq5CuT1kx2LPzndG2u5QcPvLwiTvTNDsHAUvLHyXv9y";
        prizeTokenUris[
            ScratchCardPrize.LuckyPrize
        ] = "ipfs/QmbVgLVztoB57AwfDDG34ngpNwqA3YPrhAvDG5UoMdmjxM";
    }

    function setAllowedMinter(address minter) public onlyOwner {
        allowedMinter = minter;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    error InvalidPrize();

    function safeMint(
        address to,
        ScratchCardPrize prize
    ) public onlyAllowedMinter returns (uint256) {
        require(prize != ScratchCardPrize.NoPrize, InvalidPrize());

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, prizeTokenUris[prize]);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // modifier

    error NotAllowedToMint(address sender);

    modifier onlyAllowedMinter() {
        require(msg.sender == allowedMinter || msg.sender == owner(), NotAllowedToMint(msg.sender));
        _;
    }
}
