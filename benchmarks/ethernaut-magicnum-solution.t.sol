// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {MagicNum} from "src/levels/MagicNum.sol";
import {MagicNumFactory} from "src/levels/MagicNumFactory.sol";

contract MagicNumSolve is Test {
    MagicNumFactory factory;
    MagicNum instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new MagicNumFactory();
        instance = MagicNum(factory.createInstance(player));
    }

    function testInit() public view {
        // validateInstance tidak bisa dipanggil di sini: solver masih
        // address(0) dan pemanggilan whatIsTheMeaningOfLife() ke alamat
        // kosong revert saat decode (quirk level ini).
        assertEq(instance.solver(), address(0));
    }

    function testSolve() public {
        // Solver 10 byte: creation code (12 byte) menyalin runtime code
        // (10 byte) lalu mengembalikannya.
        // Runtime: PUSH1 0x2a, PUSH1 0x00, MSTORE, PUSH1 0x20, PUSH1 0x00,
        // RETURN -> mengembalikan 32 byte = 0x2a (42). Selector calldata
        // diabaikan — kontrak hanya punya satu fungsi.
        bytes memory creation = hex"600a600c600039600a6000f3602a60005260206000f3";
        address solver;
        assembly {
            solver := create(0, add(creation, 0x20), mload(creation))
        }
        require(solver != address(0), "create failed");
        instance.setSolver(solver);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
