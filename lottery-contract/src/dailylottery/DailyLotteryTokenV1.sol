// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDailyLotteryToken} from "./interface/IDailyLotteryToken.sol";

contract DailyLotteryTokenV1 is
    IDailyLotteryToken,
    ERC721,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable
{
    string private constant TOKEN_URI = "ipfs/QmY1jzG5YiZhBZkHmPZrmG5di6TbNW5v8YsifMxnJbKZ5L";

    uint256 private _nextTokenId;

    address allowedMinter;

    constructor() ERC721("DailyLotteryToken", "DLOT") Ownable(msg.sender) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(
        address to,
        uint64 /** unused param*/
    ) public onlyAllowedMinter returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, TOKEN_URI);
        return tokenId;
    }

    function setAllowedMinter(address minter) public onlyOwner {
        allowedMinter = minter;
    }

    // the transfer of tokens is not allowed.
    error TransferDisabled(address from, address to, uint256 tokenId);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public pure override(IERC721, ERC721) {
        revert TransferDisabled(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory /* unused param*/
    ) public pure override(IERC721, ERC721) {
        revert TransferDisabled(from, to, tokenId);
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

    // check if the contract supports the interface
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
