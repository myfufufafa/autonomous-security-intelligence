// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GuessTheNumberChallenge} from "src/GuessTheNumberChallenge.sol";

// #1 Guess the number — jawaban hardcoded 42 disimpan di storage slot 0.
// State "internal" tetap publik di chain: baca via vm.load, tebak, drain 2 ether.
contract GuessTheNumberSolve is Test {
    GuessTheNumberChallenge challenge;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new GuessTheNumberChallenge{value: 1 ether}();
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        uint8 answer = uint8(uint256(vm.load(address(challenge), bytes32(uint256(0)))));
        challenge.guess{value: 1 ether}(answer);
        assertTrue(challenge.isComplete());
    }

    receive() external payable {}
}
