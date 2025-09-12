// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DailyLotteryTokenV1} from "src/dailylottery/DailyLotteryTokenV1.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract DailyLotteryTokenV1Test is Test {
    DailyLotteryTokenV1 public dailyLotteryToken;

    function setUp() public {
        dailyLotteryToken = new DailyLotteryTokenV1();
    }

    function test_mintRevertOnAllowedMinter() public {
        address accont = vm.addr(10);
        vm.prank(accont);
        vm.expectRevert(
            abi.encodeWithSelector(DailyLotteryTokenV1.NotAllowedToMint.selector, accont)
        );
        dailyLotteryToken.safeMint(accont, 1);
    }

    function test_Mint() public {
        uint256 tokenId = dailyLotteryToken.safeMint(vm.addr(1), 1);
        assertEq(dailyLotteryToken.ownerOf(tokenId), vm.addr(1));
    }

    function test_TransferFromOnDisabled() public {
        address account1 = vm.addr(1);
        address account2 = vm.addr(2);

        uint256 tokenId = dailyLotteryToken.safeMint(account2, 1);

        // change to account2
        vm.prank(account2);
        vm.expectRevert(
            abi.encodeWithSelector(
                DailyLotteryTokenV1.TransferDisabled.selector,
                account2,
                account1,
                tokenId
            )
        );
        dailyLotteryToken.transferFrom(account2, account1, tokenId);
    }

    function test_SafeTransferFromOnDisabled() public {
        address account1 = vm.addr(1);
        address account2 = vm.addr(2);

        uint256 tokenId = dailyLotteryToken.safeMint(account2, 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                DailyLotteryTokenV1.TransferDisabled.selector,
                account2,
                account1,
                tokenId
            )
        );

        dailyLotteryToken.safeTransferFrom(account2, account1, tokenId);
    }

    function test_pauseOnOwner() public {
        address accont = vm.addr(10);
        vm.prank(accont);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, accont)
        );
        dailyLotteryToken.pause();
    }

    function test_pause() public {
        dailyLotteryToken.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        dailyLotteryToken.safeMint(vm.addr(1), 1);
    }

    function test_unpauseOnOwner() public {
        address accont = vm.addr(10);
        vm.prank(accont);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, accont)
        );
        dailyLotteryToken.unpause();
    }

    function test_unpause() public {
        address account = vm.addr(10);

        dailyLotteryToken.pause();
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        dailyLotteryToken.safeMint(account, 1);

        dailyLotteryToken.unpause();
        dailyLotteryToken.safeMint(account, 1);
    }
}
