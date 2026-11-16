// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Privacy} from "src/levels/Privacy.sol";
import {PrivacyFactory} from "src/levels/PrivacyFactory.sol";

contract PrivacySolve is Test {
    PrivacyFactory factory;
    Privacy instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new PrivacyFactory();
        instance = Privacy(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // Layout storage: slot 0 locked, slot 1 ID, slot 2
        // flattening/denomination/awkwardness (packed), slot 3 data[0],
        // slot 4 data[1], slot 5 data[2]. `private` tidak menyembunyikan
        // apa pun — baca langsung dari storage.
        bytes32 data2 = vm.load(address(instance), bytes32(uint256(5)));
        instance.unlock(bytes16(data2));
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
