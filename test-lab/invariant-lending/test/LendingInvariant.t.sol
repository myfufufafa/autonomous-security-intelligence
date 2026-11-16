// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {ISimpleLending, SimpleLending, SimpleLendingBuggy} from "../src/SimpleLending.sol";

/// @title LendingHandler — satu-satunya permukaan yang di-fuzz
/// @notice Pola handler Foundry Book: batasi input ke state yang valid,
///         kelola 3 aktor, dan cerminkan akuntansi ekspektasi lewat
///         GHOST VARIABLES (termasuk akrual bunga per-aktor).
/// @dev Aturan lockstep (penting): ghost di-akru SEBELUM setiap aksi, dan
///      setiap aksi di-PRE-CHECK dengan state ghost sehingga panggilan ke
///      pool SELALU sukses. Tanpa ini, bila pool call revert, akrual di
///      pool ikut ter-rollback sementara ghost sudah maju -> false
///      positive. Karena ghost == state pool (versi benar), pre-check
///      dengan ghost bersifat eksak.
contract LendingHandler is Test {
    MockToken public token;
    ISimpleLending public pool;
    address[3] public actors;

    // --- ghost variables: "apa yang seharusnya benar sejauh ini" ---
    mapping(address => uint256) public ghost_collateral;
    mapping(address => uint256) public ghost_debt;
    uint256 public ghost_collateralSum;
    uint256 public ghost_debtSum;
    uint256 public ghost_interestSum;
    uint256 public ghost_lastAccrue;

    mapping(bytes4 => uint256) public calls;

    constructor(MockToken _token, ISimpleLending _pool, address[3] memory _actors) {
        token = _token;
        pool = _pool;
        actors = _actors;
        ghost_lastAccrue = block.timestamp;
    }

    function _pickActor(uint256 seed) internal view returns (address) {
        return actors[bound(seed, 0, 2)];
    }

    /// @notice Cerminkan accrue() protokol versi BENAR: bunga per-aktor
    ///         dengan rumus yang sama persis, pada timestamp yang sama.
    function _accrueGhost() internal {
        uint256 dt = block.timestamp - ghost_lastAccrue;
        if (dt == 0) return;
        uint256 rate = pool.RATE_PER_SECOND();
        for (uint256 i = 0; i < actors.length; i++) {
            address a = actors[i];
            uint256 interest = (ghost_debt[a] * rate * dt) / 1e18;
            if (interest > 0) {
                ghost_debt[a] += interest;
                ghost_debtSum += interest;
                ghost_interestSum += interest;
            }
        }
        ghost_lastAccrue = block.timestamp;
    }

    /// @notice Nilai utang ghost SETELAH akrual sampai block.timestamp
    ///         saat ini — view saja, tanpa mengubah state. Dipakai untuk
    ///         pre-check supaya _accrueGhost() hanya jalan bila pool
    ///         BENAR-BENAR akan dipanggil (lockstep ghost <-> pool).
    function _debtAfterAccrual(address a) internal view returns (uint256) {
        uint256 dt = block.timestamp - ghost_lastAccrue;
        return ghost_debt[a] + (ghost_debt[a] * pool.RATE_PER_SECOND() * dt) / 1e18;
    }

    function deposit(uint256 actorSeed, uint256 amountSeed) external {
        calls[this.deposit.selector]++;
        address actor = _pickActor(actorSeed);
        uint256 amount = bound(amountSeed, 1 ether, 100 ether);
        token.mint(actor, amount);
        vm.prank(actor);
        token.approve(address(pool), amount);
        _accrueGhost();
        vm.prank(actor);
        pool.deposit(amount);
        ghost_collateral[actor] += amount;
        ghost_collateralSum += amount;
    }

    function withdraw(uint256 actorSeed, uint256 amountSeed) external {
        calls[this.withdraw.selector]++;
        address actor = _pickActor(actorSeed);
        if (ghost_collateral[actor] == 0) return;
        uint256 amount = bound(amountSeed, 1, ghost_collateral[actor]);
        // Pre-check dengan nilai pasca-akrual (view) — bila gagal, return
        // SEBELUM _accrueGhost() supaya ghost tidak mendahului pool.
        uint256 newCollateral = ghost_collateral[actor] - amount;
        if (newCollateral * pool.LTV_BPS() / 10000 < _debtAfterAccrual(actor)) return;
        _accrueGhost();
        vm.prank(actor);
        pool.withdraw(amount);
        ghost_collateral[actor] -= amount;
        ghost_collateralSum -= amount;
    }

    function borrow(uint256 actorSeed, uint256 amountSeed) external {
        calls[this.borrow.selector]++;
        address actor = _pickActor(actorSeed);
        uint256 debtAfter = _debtAfterAccrual(actor);
        uint256 maxBorrow = ghost_collateral[actor] * pool.LTV_BPS() / 10000;
        if (maxBorrow <= debtAfter) return;
        maxBorrow -= debtAfter;
        uint256 amount = bound(amountSeed, 1, maxBorrow);
        _accrueGhost();
        vm.prank(actor);
        pool.borrow(amount);
        ghost_debt[actor] += amount;
        ghost_debtSum += amount;
    }

    function repay(uint256 actorSeed, uint256 amountSeed) external {
        calls[this.repay.selector]++;
        address actor = _pickActor(actorSeed);
        // Batasi ke min(ghost, on-chain): di versi benar keduanya sama;
        // di versi buggy, debtOf on-chain (usang) yang mengikat.
        uint256 debt = ghost_debt[actor];
        uint256 onChain = pool.debtOf(actor);
        if (onChain < debt) debt = onChain;
        if (debt == 0) return;
        uint256 amount = bound(amountSeed, 1, debt);
        token.mint(actor, amount);
        vm.prank(actor);
        token.approve(address(pool), amount);
        _accrueGhost();
        // NOTE: _accrueGhost di atas bisa menaikkan ghost_debt sedikit
        // (bila waktu berlalu sejak pre-check), tapi `amount` tetap <=
        // debtOf on-chain hasil akrual pool yang sama -> repay sukses.
        vm.prank(actor);
        pool.repay(amount);
        ghost_debt[actor] -= amount;
        ghost_debtSum -= amount;
    }

    /// @notice Time-delay eksplisit: majukan waktu sampai 1 hari.
    ///         Akrual tetap lazy — terjadi di aksi berikutnya.
    function warpTime(uint256 dtSeed) external {
        calls[this.warpTime.selector]++;
        uint256 dt = bound(dtSeed, 0, 1 days);
        vm.warp(block.timestamp + dt);
    }

    function callSummary() external view {
        console.log("deposit calls:", calls[this.deposit.selector]);
        console.log("withdraw calls:", calls[this.withdraw.selector]);
        console.log("borrow calls:", calls[this.borrow.selector]);
        console.log("repay calls:", calls[this.repay.selector]);
        console.log("warpTime calls:", calls[this.warpTime.selector]);
    }
}

/// @title Basis test invariant — dipakai versi benar DAN versi buggy
abstract contract LendingInvariantBase is Test {
    MockToken internal token;
    ISimpleLending internal pool;
    LendingHandler internal handler;
    address[3] internal actors = [address(0x1111), address(0x2222), address(0x3333)];

    function deployPool(MockToken _token) internal virtual returns (ISimpleLending);

    function setUp() public {
        token = new MockToken();
        pool = deployPool(token);
        handler = new LendingHandler(token, pool, actors);
        targetContract(address(handler));
    }

    function _sumDebt() internal view returns (uint256 s) {
        for (uint256 i = 0; i < actors.length; i++) s += pool.debtOf(actors[i]);
    }

    function _sumCollateral() internal view returns (uint256 s) {
        for (uint256 i = 0; i < actors.length; i++) s += pool.collateralOf(actors[i]);
    }

    /// TRIPWIRE UTAMA: jumlah utang per-user harus sama dengan totalBorrows.
    /// Di versi buggy, accrue() hanya menaikkan totalBorrows -> gagal
    /// begitu ada waktu berlalu dengan utang terbuka.
    function invariant_debtAccounting() public view {
        assertEq(_sumDebt(), pool.totalBorrows(), "sum debtOf != totalBorrows");
    }

    function invariant_collateralAccounting() public view {
        assertEq(_sumCollateral(), pool.totalCollateral(), "sum collateralOf != totalCollateral");
    }

    /// Ghost vs on-chain: ghost (akrual benar) vs debtOf (apa adanya).
    /// Di versi buggy, ghost terus mengakru sementara debtOf mandek.
    function invariant_ghostDebtMatches() public view {
        assertEq(handler.ghost_debtSum(), _sumDebt(), "ghost debt != sum debtOf");
    }

    function invariant_ghostCollateralMatches() public view {
        assertEq(handler.ghost_collateralSum(), pool.totalCollateral(), "ghost collateral != totalCollateral");
    }

    /// Solvabilitas: yang dipegang pool + yang dipinjamkan (termasuk
    /// bunga) harus selalu cukup menutup semua titipan.
    /// (Versi awal assert `balance <= totalCollateral` SALAH dan
    /// dihapus: bunga yang dibayar peminjam adalah token yang masuk
    /// ke pool, jadi saldo pool sah melebihi total titipan.)
    function invariant_solvency() public view {
        assertGe(
            token.balanceOf(address(pool)) + pool.totalBorrows(),
            pool.totalCollateral(),
            "pool insolvent"
        );
    }

    /// Identitas saldo eksak (aliran token): saldo pool = titipan
    /// - pokok beredar + bunga yang pernah terakru. Di versi benar
    /// berlaku tepat; di versi buggy hanya meleset dust (pembulatan
    /// bunga global vs per-aktor) — BUKAN tripwire utama.
    function invariant_poolBalanceIdentity() public view {
        assertEq(
            token.balanceOf(address(pool)),
            handler.ghost_collateralSum() + handler.ghost_interestSum() - handler.ghost_debtSum(),
            "pool balance identity broken"
        );
    }

    /// Hook afterInvariant (Foundry Book): cek agregat akhir tiap run —
    /// saldo pool harus sama dengan titipan + bunga terakru - total utang.
    /// (Urutan penjumlahan penting: `collateral - (debt - interest)`
    /// underflow bila bunga yang sudah dilunasi membuat debt < interest.)
    function afterInvariant() public view {
        assertEq(
            token.balanceOf(address(pool)),
            handler.ghost_collateralSum() + handler.ghost_interestSum() - handler.ghost_debtSum(),
            "afterInvariant: pool balance mismatch"
        );
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}

contract LendingInvariantTest is LendingInvariantBase {
    function deployPool(MockToken _token) internal override returns (ISimpleLending) {
        return new SimpleLending(_token);
    }
}

contract LendingBuggyInvariantTest is LendingInvariantBase {
    function deployPool(MockToken _token) internal override returns (ISimpleLending) {
        return new SimpleLendingBuggy(_token);
    }
}

/// @title AccrualDivergenceTest — demo deterministik (bukan fuzz)
/// @notice Urutan tetap: deposit 100 ether, pinjam 50 ether, warp 30 hari,
///         picu akrual dengan deposit 1 wei, lalu bandingkan.
///         Menunjukkan selisih dalam angka BESAR (bukan dust fuzz).
contract AccrualDivergenceTest is Test {
    MockToken internal token;
    address internal alice = address(0xA11CE);

    function _setup(ISimpleLending pool) internal {
        token.mint(alice, 200 ether);
        vm.startPrank(alice);
        token.approve(address(pool), type(uint256).max);
        pool.deposit(100 ether);
        pool.borrow(50 ether);
        vm.stopPrank();
        vm.warp(block.timestamp + 30 days);
        // Picu accrue() lewat aksi apa pun (deposit 1 wei).
        vm.prank(alice);
        token.mint(alice, 1);
        vm.prank(alice);
        token.approve(address(pool), 1);
        vm.prank(alice);
        pool.deposit(1);
    }

    function test_correctAccrualMatches() public {
        SimpleLending pool = new SimpleLending(token = new MockToken());
        _setup(pool);
        uint256 sumDebt = pool.debtOf(alice);
        uint256 total = pool.totalBorrows();
        console.log("CORRECT  sum debtOf:", sumDebt);
        console.log("CORRECT  totalBorrows:", total);
        console.log("CORRECT  interest accrued:", total - 50 ether);
        assertEq(sumDebt, total, "correct version must match exactly");
    }

    function test_buggyAccrualDiverges() public {
        SimpleLendingBuggy pool = new SimpleLendingBuggy(token = new MockToken());
        _setup(pool);
        uint256 sumDebt = pool.debtOf(alice);
        uint256 total = pool.totalBorrows();
        console.log("BUGGY    sum debtOf:", sumDebt);
        console.log("BUGGY    totalBorrows:", total);
        console.log("BUGGY    hidden interest (total - sum):", total - sumDebt);
        assertTrue(sumDebt < total, "buggy version must diverge");
        assertEq(sumDebt, 50 ether, "per-user debt never accrued");
    }
}
