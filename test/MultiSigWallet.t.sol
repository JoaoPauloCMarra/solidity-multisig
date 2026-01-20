// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] owners;
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address nonOwner = address(0x4);

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        wallet = new MultiSigWallet(owners, 2);
        vm.deal(address(wallet), 10 ether);
    }

    function test_constructor_setsOwners() public view {
        assertEq(wallet.owners(0), owner1);
        assertEq(wallet.owners(1), owner2);
        assertEq(wallet.owners(2), owner3);
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
    }

    function test_constructor_setsThreshold() public view {
        assertEq(wallet.threshold(), 2);
    }

    function test_constructor_revertsOnEmptyOwners() public {
        address[] memory empty = new address[](0);
        vm.expectRevert(MultiSigWallet.OwnersRequired.selector);
        new MultiSigWallet(empty, 1);
    }

    function test_constructor_revertsOnZeroThreshold() public {
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        new MultiSigWallet(owners, 0);
    }

    function test_constructor_revertsOnThresholdTooHigh() public {
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        new MultiSigWallet(owners, 4);
    }

    function test_constructor_revertsOnDuplicateOwner() public {
        owners.push(owner1);
        vm.expectRevert(MultiSigWallet.OwnerExists.selector);
        new MultiSigWallet(owners, 2);
    }

    function test_constructor_revertsOnZeroAddress() public {
        owners.push(address(0));
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(owners, 2);
    }

    function test_receive_acceptsEth() public {
        uint256 before = address(wallet).balance;
        vm.deal(nonOwner, 1 ether);
        vm.prank(nonOwner);
        (bool ok,) = address(wallet).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, before + 1 ether);
    }

    function test_submit_createsTransaction() public {
        vm.prank(owner1);
        uint256 txId = wallet.submit(nonOwner, 1 ether, "");
        assertEq(txId, 0);
        assertEq(wallet.getTransactionCount(), 1);

        (address to, uint256 value,, bool executed, uint256 confirmCount) = wallet.getTransaction(0);
        assertEq(to, nonOwner);
        assertEq(value, 1 ether);
        assertFalse(executed);
        assertEq(confirmCount, 0);
    }

    function test_submit_revertsForNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.submit(nonOwner, 1 ether, "");
    }

    function test_confirm_incrementsCount() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(owner1);
        wallet.confirm(0);
        assertTrue(wallet.isConfirmed(0, owner1));

        (,,,, uint256 confirmCount) = wallet.getTransaction(0);
        assertEq(confirmCount, 1);
    }

    function test_confirm_revertsOnDoubleConfirm() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(owner1);
        wallet.confirm(0);

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyConfirmed.selector);
        wallet.confirm(0);
    }

    function test_confirm_revertsForNonOwner() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.confirm(0);
    }

    function test_execute_sendsEth() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(owner1);
        wallet.confirm(0);
        vm.prank(owner2);
        wallet.confirm(0);

        uint256 before = nonOwner.balance;
        vm.prank(owner1);
        wallet.execute(0);

        assertEq(nonOwner.balance, before + 1 ether);
        (,,, bool executed,) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function test_execute_revertsIfThresholdNotMet() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(owner1);
        wallet.confirm(0);

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.ThresholdNotMet.selector);
        wallet.execute(0);
    }

    function test_execute_revertsOnDoubleExecute() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(owner1);
        wallet.confirm(0);
        vm.prank(owner2);
        wallet.confirm(0);

        vm.prank(owner1);
        wallet.execute(0);

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.execute(0);
    }

    function test_revoke_decrementsCount() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(owner1);
        wallet.confirm(0);

        vm.prank(owner1);
        wallet.revoke(0);

        assertFalse(wallet.isConfirmed(0, owner1));
        (,,,, uint256 confirmCount) = wallet.getTransaction(0);
        assertEq(confirmCount, 0);
    }

    function test_revoke_revertsIfNotConfirmed() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxNotConfirmed.selector);
        wallet.revoke(0);
    }

    function test_addOwner_viaWalletTx() public {
        address newOwner = address(0x5);
        bytes memory data = abi.encodeWithSelector(MultiSigWallet.addOwner.selector, newOwner);

        vm.prank(owner1);
        wallet.submit(address(wallet), 0, data);

        vm.prank(owner1);
        wallet.confirm(0);
        vm.prank(owner2);
        wallet.confirm(0);

        vm.prank(owner1);
        wallet.execute(0);

        assertTrue(wallet.isOwner(newOwner));
        assertEq(wallet.getOwners().length, 4);
    }

    function test_removeOwner_viaWalletTx() public {
        bytes memory data = abi.encodeWithSelector(MultiSigWallet.removeOwner.selector, owner3);

        vm.prank(owner1);
        wallet.submit(address(wallet), 0, data);

        vm.prank(owner1);
        wallet.confirm(0);
        vm.prank(owner2);
        wallet.confirm(0);

        vm.prank(owner1);
        wallet.execute(0);

        assertFalse(wallet.isOwner(owner3));
        assertEq(wallet.getOwners().length, 2);
    }

    function test_changeThreshold_viaWalletTx() public {
        bytes memory data = abi.encodeWithSelector(MultiSigWallet.changeThreshold.selector, 3);

        vm.prank(owner1);
        wallet.submit(address(wallet), 0, data);

        vm.prank(owner1);
        wallet.confirm(0);
        vm.prank(owner2);
        wallet.confirm(0);

        vm.prank(owner1);
        wallet.execute(0);

        assertEq(wallet.threshold(), 3);
    }

    function test_getOwners() public view {
        address[] memory result = wallet.getOwners();
        assertEq(result.length, 3);
        assertEq(result[0], owner1);
        assertEq(result[1], owner2);
        assertEq(result[2], owner3);
    }
}
