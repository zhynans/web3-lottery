// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ScratchCardTokenV1} from "src/scratchcard/ScratchCardTokenV1.sol";
import {ScratchCardPrize} from "src/scratchcard/ScratchCardDef.sol";
import {IScratchCardToken} from "src/scratchcard/interface/IScratchCardToken.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ScratchCardTokenV1Test is Test {
    ScratchCardTokenV1 public token;
    address public owner;
    address public minter;
    address public user1;
    address public user2;

    // Expected token URIs for each prize
    string public constant GRAND_PRIZE_URI = "ipfs/QmcEZLE5VLosTYtrim8rDfLfj3KkGRFUSisoihXo2LPJs4";
    string public constant SMALL_PRIZE_URI = "ipfs/QmZGq5CuT1kx2LPzndG2u5QcPvLwiTvTNDsHAUvLHyXv9y";
    string public constant LUCKY_PRIZE_URI = "ipfs/QmbVgLVztoB57AwfDDG34ngpNwqA3YPrhAvDG5UoMdmjxM";

    function setUp() public {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.prank(owner);
        token = new ScratchCardTokenV1();
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsCorrectNameAndSymbol() public view {
        assertEq(token.name(), "ScratchCardToken");
        assertEq(token.symbol(), "SCR");
    }

    function test_Constructor_SetsCorrectOwner() public view {
        assertEq(token.owner(), owner);
    }

    function test_Constructor_InitializesPrizeTokenUris() public view {
        assertEq(token.prizeTokenUris(ScratchCardPrize.GrandPrize), GRAND_PRIZE_URI);
        assertEq(token.prizeTokenUris(ScratchCardPrize.SmallPrize), SMALL_PRIZE_URI);
        assertEq(token.prizeTokenUris(ScratchCardPrize.LuckyPrize), LUCKY_PRIZE_URI);
    }

    function test_Constructor_InitializesNextTokenId() public {
        // Next token ID should start at 0
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.GrandPrize);
        assertEq(tokenId, 0);
    }

    // ============ Allowed Minter Tests ============

    function test_SetAllowedMinter_OnlyOwner() public {
        vm.prank(minter);
        vm.expectRevert();
        token.setAllowedMinter(minter);

        vm.prank(owner);
        token.setAllowedMinter(minter);
        // No revert means success
    }

    function test_SetAllowedMinter_SetsCorrectMinter() public {
        vm.prank(owner);
        token.setAllowedMinter(minter);

        // We can't directly access the allowedMinter variable, but we can test it through safeMint
        vm.prank(minter);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.GrandPrize);
        assertEq(tokenId, 0);
    }

    // ============ Safe Mint Tests ============

    function test_SafeMint_OnlyAllowedMinter() public {
        // Owner can always mint
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.GrandPrize);
        assertEq(tokenId, 0);

        // Set minter and test
        vm.prank(owner);
        token.setAllowedMinter(minter);

        vm.prank(minter);
        tokenId = token.safeMint(user2, ScratchCardPrize.SmallPrize);
        assertEq(tokenId, 1);

        // Random user cannot mint
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(ScratchCardTokenV1.NotAllowedToMint.selector, user1)
        );
        token.safeMint(user2, ScratchCardPrize.LuckyPrize);
    }

    function test_SafeMint_InvalidPrize() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ScratchCardTokenV1.InvalidPrize.selector));
        token.safeMint(user1, ScratchCardPrize.NoPrize);
    }

    function test_SafeMint_GrandPrize() public {
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.GrandPrize);

        assertEq(token.ownerOf(tokenId), user1);
        assertEq(token.tokenURI(tokenId), GRAND_PRIZE_URI);
        assertEq(token.balanceOf(user1), 1);
    }

    function test_SafeMint_SmallPrize() public {
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.SmallPrize);

        assertEq(token.ownerOf(tokenId), user1);
        assertEq(token.tokenURI(tokenId), SMALL_PRIZE_URI);
        assertEq(token.balanceOf(user1), 1);
    }

    function test_SafeMint_LuckyPrize() public {
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.LuckyPrize);

        assertEq(token.ownerOf(tokenId), user1);
        assertEq(token.tokenURI(tokenId), LUCKY_PRIZE_URI);
        assertEq(token.balanceOf(user1), 1);
    }

    function test_SafeMint_IncrementsTokenId() public {
        vm.startPrank(owner);

        uint256 tokenId1 = token.safeMint(user1, ScratchCardPrize.GrandPrize);
        uint256 tokenId2 = token.safeMint(user2, ScratchCardPrize.SmallPrize);
        uint256 tokenId3 = token.safeMint(user1, ScratchCardPrize.LuckyPrize);

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(tokenId3, 2);

        vm.stopPrank();
    }

    function test_SafeMint_EmitsTransferEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), user1, 0);
        token.safeMint(user1, ScratchCardPrize.GrandPrize);
    }

    // ============ Pause Tests ============

    function test_Pause_OnlyOwner() public {
        vm.prank(minter);
        vm.expectRevert();
        token.pause();

        vm.prank(owner);
        token.pause();
        assertTrue(token.paused());
    }

    function test_Unpause_OnlyOwner() public {
        vm.prank(owner);
        token.pause();
        assertTrue(token.paused());

        vm.prank(minter);
        vm.expectRevert();
        token.unpause();

        vm.prank(owner);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_SafeMint_RevertsWhenPaused() public {
        vm.prank(owner);
        token.pause();

        vm.prank(owner);
        vm.expectRevert();
        token.safeMint(user1, ScratchCardPrize.GrandPrize);
    }

    function test_Transfer_RevertsWhenPaused() public {
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.GrandPrize);

        vm.prank(owner);
        token.pause();

        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(user1, user2, tokenId);
    }

    function test_Transfer_AlwaysReverts() public {
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.GrandPrize);

        // Test transferFrom - should always revert
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(ScratchCardTokenV1.TokenTransferNotAllowed.selector)
        );
        token.transferFrom(user1, user2, tokenId);

        // Test safeTransferFrom - should always revert
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(ScratchCardTokenV1.TokenTransferNotAllowed.selector)
        );
        token.safeTransferFrom(user1, user2, tokenId);

        // Test safeTransferFrom with data - should always revert
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(ScratchCardTokenV1.TokenTransferNotAllowed.selector)
        );
        token.safeTransferFrom(user1, user2, tokenId, "");
    }

    // ============ ERC721 Override Tests ============

    function test_TokenURI_ReturnsCorrectURI() public {
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user1, ScratchCardPrize.GrandPrize);

        assertEq(token.tokenURI(tokenId), GRAND_PRIZE_URI);
    }

    function test_TokenURI_RevertsForNonExistentToken() public {
        vm.expectRevert();
        token.tokenURI(999);
    }

    function test_SupportsInterface_ERC721() public view {
        // ERC721 interface ID
        assertTrue(token.supportsInterface(0x80ac58cd));
    }

    function test_SupportsInterface_ERC721Metadata() public view {
        // ERC721Metadata interface ID
        assertTrue(token.supportsInterface(0x5b5e139f));
    }

    function test_SupportsInterface_ERC721Enumerable() public view {
        // ERC721Enumerable interface ID
        assertFalse(token.supportsInterface(0x780e9d63));
    }

    function test_SupportsInterface_ERC165() public view {
        // ERC165 interface ID
        assertTrue(token.supportsInterface(0x01ffc9a7));
    }

    // ============ Edge Cases ============

    function test_SafeMint_ToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert();
        token.safeMint(address(0), ScratchCardPrize.GrandPrize);
    }

    function test_MultipleMintsToSameUser() public {
        vm.startPrank(owner);

        token.safeMint(user1, ScratchCardPrize.GrandPrize);
        token.safeMint(user1, ScratchCardPrize.SmallPrize);
        token.safeMint(user1, ScratchCardPrize.LuckyPrize);

        assertEq(token.balanceOf(user1), 3);
        vm.stopPrank();
    }

    function test_ChangeAllowedMinter() public {
        address newMinter = makeAddr("newMinter");

        vm.prank(owner);
        token.setAllowedMinter(minter);

        vm.prank(minter);
        token.safeMint(user1, ScratchCardPrize.GrandPrize);

        vm.prank(owner);
        token.setAllowedMinter(newMinter);

        // Old minter can no longer mint
        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(ScratchCardTokenV1.NotAllowedToMint.selector, minter)
        );
        token.safeMint(user1, ScratchCardPrize.SmallPrize);

        // New minter can mint
        vm.prank(newMinter);
        uint256 tokenId = token.safeMint(user2, ScratchCardPrize.SmallPrize);
        assertEq(tokenId, 1);
    }
}
