// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GuessTheSecretNumber} from "src/GuessSecretNumber.sol";

// #2 Guess the secret number — jawaban uint8 (ruang 256) di-hash keccak256
// dan hash-nya publik di storage slot 0. Brute-force 256 nilai OFF-CHAIN
// (tanpa memanggil guess), lalu tebak sekali dengan nilai yang benar.
contract GuessTheSecretNumberSolve is Test {
    GuessTheSecretNumber challenge;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new GuessTheSecretNumber{value: 1 ether}();
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        bytes32 answerHash = vm.load(address(challenge), bytes32(uint256(0)));
        uint8 n;
        bool found;
        for (uint256 i = 0; i < 256; i++) {
            if (keccak256(abi.encodePacked(uint8(i))) == answerHash) {
                n = uint8(i);
                found = true;
                break;
            }
        }
        assertTrue(found);
        challenge.guess{value: 1 ether}(n);
        assertTrue(challenge.isComplete());
    }

    receive() external payable {}
}
