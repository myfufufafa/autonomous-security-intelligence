# Damn Vulnerable DeFi — Baseline (Challenge #1: Unstoppable)

**Misi:** Autonomous Bounty Intelligence & Skill Evolution — Pass 2 fase A, item #6
**Tanggal:** 16 November 2026
**Sumber:** https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry
(MIT, 515★, update 11 Nov 2026; port Foundry dari OpenZeppelin
Damn Vulnerable DeFi) — clone `--depth 1` ke `/tmp/dvd` (1,6 MB).
**Status:** Port BERJALAN di Foundry 1.9.0 untuk tantangan #1 (dengan
penyesuaian dependensi, lihat §1). Tantangan #1 SELESAI — baseline tercatat.
12 tantangan sisanya BELUM dikerjakan (jadwal pass berikut).

## 1. Setup port — hasil uji

| Aspek | Hasil |
|---|---|
| Clone mentah (`/tmp/dvd`) + `forge build` | **GAGAL.** `lib/` berisi 4 submodul KOSONG (forge-std, openzeppelin-contracts, safe-contracts, openzeppelin-contracts-upgradeable) karena clone tanpa `--recurse-submodules`. Error pertama: `Source "lib/safe-contracts/contracts/GnosisSafe.sol" not found`. |
| Solusi untuk tantangan #1 | Proyek minimal `/tmp/dvd-baseline` (hanya file tantangan #1 + `DamnValuableToken` + `Utilities`) dengan dependensi dari copy lokal yang sudah ada: `forge-std` (dari hunt Sparklend) + `openzeppelin-contracts` **v4.9.3** (dari `safe-bugbounty/poc/hunter-passkey`). Build: **OK**. |
| Jebakan versi OZ | Port memakai path OZ v4 (`openzeppelin-contracts/security/ReentrancyGuard.sol`). Copy lokal OZ **v5.0.2 / v5.7.0 TIDAK COCOK** (di v5 path pindah ke `utils/ReentrancyGuard.sol`). Yang dipakai: v4.9.3 — diverifikasi path-nya ada sebelum copy. |
| Full port (13 level) | BELUM siap: `safe-contracts` + `openzeppelin-contracts-upgradeable` tidak punya copy lokal; butuh `git submodule update --init` (fetch jaringan) atau copy setara. Ditunda ke pass berikut — JANGAN dipaksa (sesuai tugas). |
| RPC / fork | Tidak dibutuhkan — semua tantangan DVD berjalan lokal (tanpa fork). |
| Foundry | 1.9.0 — kompatibel. Test berjalan 16 ms (plus ~2 detik compile). |

**Lokasi kerja:** proyek minimal `/tmp/dvd-baseline` (scratch, ephemeral —
bisa dibuat ulang dari `/tmp/dvd` + copy lib lokal). Solusi tantangan #1
yang sudah lolos disimpan permanen di repo ini:
`benchmarks/dvd-unstoppable-solution.t.sol` (84 baris).

## 2. Tantangan #1 — Unstoppable

**Deskripsi (README tantangan):** pool lending dengan 1 juta DVT, menawarkan
flash loan gratis. Attacker mulai dengan 100 DVT. Tujuan: hentikan pool
sehingga tidak bisa lagi memberikan flash loan.

**Kontrak yang dibaca (sebelum solve):**
`src/Contracts/unstoppable/UnstoppableLender.sol` (62 baris),
`ReceiverUnstoppable.sol`, `DamnValuableToken.sol`, test
`Unstoppable.t.sol` (syarat sukses: `executeFlashLoan(10)` harus revert
dengan `UnstoppableLender.AssertionViolated`).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function flashLoan(uint256 borrowAmount) external nonReentrant {
    uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
    if (balanceBefore < borrowAmount) revert NotEnoughTokensInPool();
    // Ensured by the protocol via the `depositTokens` function
    if (poolBalance != balanceBefore) revert AssertionViolated();
    ...
}
```

Pool melacak saldonya dengan akuntansi internal (`poolBalance`, hanya
bertambah lewat `depositTokens()`), lalu MENG-ASSERT bahwa akuntansi itu
sama dengan saldo token sebenarnya. Asumsi itu salah: SIAPA PUN bisa
`transfer` DVT langsung ke alamat pool — saldo riil naik TANPA menyentuh
`poolBalance`. Sejak itu `poolBalance != balanceBefore` SELAMANYA, dan
semua flash loan revert dengan `AssertionViolated`. Tidak ada fungsi
`sync` / koreksi — kerusakannya permanen (DoS).

**Kelas bug:** mismatch akuntansi internal vs saldo aktual (kelas yang
sama dengan donasi Euler di item #3 — di sana donasi merusak health
check, di sini transfer langsung merusak assert).

### Exploit (PoC — 1 baris efektif)

```solidity
vm.startPrank(attacker);
dvt.transfer(address(unstoppableLender), 1); // 1 wei cukup
vm.stopPrank();
```

### Hasil

```
forge test --match-contract Unstoppable
[PASS] testExploit() (gas: 99499)
Logs: 🧨 Let's see if you can break it... 🧨 / 🎉 Congratulations! 🎉
Suite result: ok. 1 passed; 0 failed — 16.15ms (test), ~2s total.
```

## 3. Baseline kemampuan (pengukuran jujur)

| Metrik | Hasil |
|---|---|
| Akurasi identifikasi bug | **1/1** — root cause benar di percobaan pertama, tanpa false positive |
| Root cause | Benar + tepat (mismatch `poolBalance` vs `balanceOf`, DoS permanen, tanpa fungsi sync) |
| Kualitas PoC | Minimal (1 transfer 1 wei) + memakai syarat sukses resmi test (`AssertionViolated`) |
| Ketepatan severity | Benar: **DoS/availability** — bukan pencurian dana. Di program bounty nyata ini kelas Medium (griefing, tak ada dana hilang), bukan Critical. |
| Waktu analisis | **~5 menit** dari membaca kontrak sampai exploit tertulis |
| Waktu setup port | **~25 menit** (mayoritas: dependensi — submodul kosong, OZ v4 vs v5, build repo penuh gagal) |
| Percobaan gagal | 0 untuk solve-nya; 2 untuk setup (build repo penuh gagal 2x sebelum proyek minimal) |

**Catatan kejujuran:** Unstoppable adalah tantangan #1 yang paling dikenal
di DVD — polanya sudah saya kenal dari literatur. Jadi baseline ini
mengukur EKSEKUSI (setup + solve + verifikasi berjalan), BUKAN penemuan
dari nol. Tantangan yang lebih sulit (truster, side-entrance, rewarder,
selfie, climber, ...) adalah pengukur yang sesungguhnya — di situlah
baseline akan diuji ulang di pass berikut. Skor baseline saat ini:
**1/13 tantangan selesai.**

## 4. Yang dibawa ke perburuan

- Pola "akuntansi internal vs saldo aktual" adalah pola yang SAMA dengan
  Euler (donasi merusak health check) — dan muncul di banyak protokol
  (share-price, `totalAssets` vs `balanceOf`, `poolBalance` vs saldo).
  Di audit berikutnya, setiap `assert(balance == accounting)` atau
  `require(balance == expected)` WAJIB ditanya: "bisakah saldo berubah
  tanpa lewat fungsi yang mengupdate akuntansi?" (transfer langsung,
  donasi, `selfdestruct` force-ETH, rebate, dsb.)
- Setup port DVD sekarang terdokumentasi — tantangan #2–#13 tinggal
  menambah file level + 2 lib yang kurang (safe-contracts,
  OZ-upgradeable), tanpa mengulang riset dependensi.

## 5. Langkah berikut

- [ ] Lengkapi setup full port (fetch `safe-contracts` +
  `openzeppelin-contracts-upgradeable` sebagai submodul, atau copy lokal
  bila ada) — prasyarat tantangan #2+.
- [ ] Kerjakan tantangan #2 naive-receiver → #13, catat per tantangan:
  akurasi, root cause, false positive, waktu.
- [ ] Bandingkan baseline SEBELUM vs SESUDAH skill baru dipakai (item #1
  invariant testing, item #4 aeon sc-audit) — itulah fungsi benchmark ini.
