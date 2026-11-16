// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GuessRandomNumber} from "src/GuessRandomNumber.sol";

// #3 Guess the random number — jawaban dihitung di constructor dari
// blockhash(block.number-1) + block.timestamp: dua nilai PUBLIK yang
// bisa dihitung ulang siapa pun. Di Foundry, blok deployment == blok
// test, jadi rumus yang sama menghasilkan jawaban yang sama.
contract GuessRandomNumberSolve is Test {
    GuessRandomNumber challenge;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new GuessRandomNumber{value: 1 ether}();
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        uint8 answer = uint8(
            uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))
        );
        challenge.guess{value: 1 ether}(answer);
        assertTrue(challenge.isComplete());
    }

    receive() external payable {}
}
