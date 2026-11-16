// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockToken} from "./MockToken.sol";

/// @title ISimpleLending — antarmuka bersama versi benar & versi buggy
interface ISimpleLending {
    function RATE_PER_SECOND() external view returns (uint256);
    function LTV_BPS() external view returns (uint256);
    function totalCollateral() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function collateralOf(address user) external view returns (uint256);
    function debtOf(address user) external view returns (uint256);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repay(uint256 amount) external;
}

/// @title SimpleLending — protokol lending lokal MINIMAL (ditulis sendiri)
/// @notice Model: satu aset jadi collateral SEKALIGUS aset pinjaman (seperti
///         pool lending sederhana). Bunga simple interest ~5% APR, diakru
///         secara lazy di awal setiap fungsi mutasi, didistribusikan
///         per-peminjam — jadi totalBorrows SELALU sama dengan jumlah
///         debtOf semua peminjam (tepat, tanpa rounding drift).
/// @dev Toy only: `accrue()` iterasi array borrowers (gas tak terbatas),
///      tidak ada oracle/liquidation. Cukup untuk melatih invariant testing.
contract SimpleLending is ISimpleLending {
    MockToken public immutable token;

    uint256 public constant override LTV_BPS = 7500; // 75%
    // 5% APR dalam fixed point 1e18 per detik: 0.05e18 / 31536000 = 1585489599
    uint256 public constant override RATE_PER_SECOND = 1585489599;

    uint256 public override totalCollateral;
    uint256 public override totalBorrows;
    uint256 public lastAccrue;

    mapping(address => uint256) public override collateralOf;
    mapping(address => uint256) public override debtOf;

    address[] public borrowers;
    mapping(address => bool) public isBorrower;

    constructor(MockToken _token) {
        token = _token;
        lastAccrue = block.timestamp;
    }

    /// @notice Akrual bunga BENAR: bunga dihitung per-peminjam, dan
    ///         totalBorrows bertambah dari JUMLAH bunga per-peminjam yang
    ///         sama persis — jadi sum(debtOf) == totalBorrows selalu.
    function accrue() internal {
        uint256 dt = block.timestamp - lastAccrue;
        if (dt == 0 || totalBorrows == 0) {
            lastAccrue = block.timestamp;
            return;
        }
        for (uint256 i = 0; i < borrowers.length; i++) {
            address u = borrowers[i];
            uint256 interest = (debtOf[u] * RATE_PER_SECOND * dt) / 1e18;
            if (interest > 0) {
                debtOf[u] += interest;
                totalBorrows += interest;
            }
        }
        lastAccrue = block.timestamp;
    }

    function deposit(uint256 amount) external override {
        accrue();
        require(amount > 0, "zero amount");
        token.transferFrom(msg.sender, address(this), amount);
        collateralOf[msg.sender] += amount;
        totalCollateral += amount;
    }

    function withdraw(uint256 amount) external override {
        accrue();
        require(amount > 0 && collateralOf[msg.sender] >= amount, "bad withdraw");
        uint256 newCollateral = collateralOf[msg.sender] - amount;
        // Health factor harus tetap >= 1 setelah penarikan.
        require(newCollateral * LTV_BPS / 10000 >= debtOf[msg.sender], "HF < 1");
        collateralOf[msg.sender] = newCollateral;
        totalCollateral -= amount;
        token.transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external override {
        accrue();
        require(amount > 0, "zero amount");
        require(
            debtOf[msg.sender] + amount <= collateralOf[msg.sender] * LTV_BPS / 10000,
            "exceeds LTV"
        );
        if (!isBorrower[msg.sender]) {
            isBorrower[msg.sender] = true;
            borrowers.push(msg.sender);
        }
        debtOf[msg.sender] += amount;
        totalBorrows += amount;
        token.transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external override {
        accrue();
        require(amount > 0, "zero amount");
        if (amount > debtOf[msg.sender]) amount = debtOf[msg.sender];
        if (amount == 0) return;
        token.transferFrom(msg.sender, address(this), amount);
        debtOf[msg.sender] -= amount;
        totalBorrows -= amount;
    }
}

/// @title SimpleLendingBuggy — SATU bug yang disengaja (untuk TEST)
/// @notice Identik dengan SimpleLending, KECUALI `accrue()`: bunga hanya
///         ditambahkan ke `totalBorrows` (rumus global) dan TIDAK ke
///         `debtOf` per-peminjam. Akibatnya:
///         1. sum(debtOf) < totalBorrows begitu ada waktu berlalu + utang.
///         2. Cek health-factor di borrow()/withdraw() memakai utang usang
///            (lebih kecil) -> peminjam bisa over-borrow.
///         3. repay() dibatasi debtOf (usang) -> bunga yang terakru tidak
///            pernah bisa dilunasi, totalBorrows macet > 0.
///         Ini pola bug NYATA: mismatch akrual bunga global vs per-user.
contract SimpleLendingBuggy is ISimpleLending {
    MockToken public immutable token;

    uint256 public constant override LTV_BPS = 7500;
    uint256 public constant override RATE_PER_SECOND = 1585489599;

    uint256 public override totalCollateral;
    uint256 public override totalBorrows;
    uint256 public lastAccrue;

    mapping(address => uint256) public override collateralOf;
    mapping(address => uint256) public override debtOf;

    address[] public borrowers;
    mapping(address => bool) public isBorrower;

    constructor(MockToken _token) {
        token = _token;
        lastAccrue = block.timestamp;
    }

    /// @dev BUG: bunga diakru ke totalBorrows saja, debtOf tidak disentuh.
    function accrue() internal {
        uint256 dt = block.timestamp - lastAccrue;
        if (dt == 0 || totalBorrows == 0) {
            lastAccrue = block.timestamp;
            return;
        }
        uint256 interest = (totalBorrows * RATE_PER_SECOND * dt) / 1e18;
        totalBorrows += interest;
        lastAccrue = block.timestamp;
    }

    function deposit(uint256 amount) external override {
        accrue();
        require(amount > 0, "zero amount");
        token.transferFrom(msg.sender, address(this), amount);
        collateralOf[msg.sender] += amount;
        totalCollateral += amount;
    }

    function withdraw(uint256 amount) external override {
        accrue();
        require(amount > 0 && collateralOf[msg.sender] >= amount, "bad withdraw");
        uint256 newCollateral = collateralOf[msg.sender] - amount;
        require(newCollateral * LTV_BPS / 10000 >= debtOf[msg.sender], "HF < 1");
        collateralOf[msg.sender] = newCollateral;
        totalCollateral -= amount;
        token.transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external override {
        accrue();
        require(amount > 0, "zero amount");
        require(
            debtOf[msg.sender] + amount <= collateralOf[msg.sender] * LTV_BPS / 10000,
            "exceeds LTV"
        );
        if (!isBorrower[msg.sender]) {
            isBorrower[msg.sender] = true;
            borrowers.push(msg.sender);
        }
        debtOf[msg.sender] += amount;
        totalBorrows += amount;
        token.transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external override {
        accrue();
        require(amount > 0, "zero amount");
        if (amount > debtOf[msg.sender]) amount = debtOf[msg.sender];
        if (amount == 0) return;
        token.transferFrom(msg.sender, address(this), amount);
        debtOf[msg.sender] -= amount;
        totalBorrows -= amount;
    }
}
