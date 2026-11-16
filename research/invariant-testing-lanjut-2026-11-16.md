# Invariant Testing Lanjut (Foundry) — STUDY + PRACTICE + TEST

**Misi:** Autonomous Bounty Intelligence & Skill Evolution — Pass 2 fase A, item #1
**Tanggal:** 16 November 2026
**Siklus:** STUDY → PRACTICE → TEST (IDENTIFY + SEARCH sudah di pass 1)
**Status:** TEST LOLOS — skill TERBUKTI bekerja di lab lokal. Adopsi sebagai custom
skill MENUNGGU verifikasi main chat (aturan misi). Bukan klaim "dikuasai" — baru
1 protokol toy, 1 kelas bug.

## 1. STUDY — apa yang dipelajari

### 1.1 Foundry Book, bab "Invariant Testing" (dibaca penuh 16 Nov 2026)

Sumber: https://book.getfoundry.sh/forge/invariant-testing (Apache-2.0).

Konsep inti: nyatakan properti yang HARUS selalu benar, lalu biarkan Foundry
menjalankan urutan panggilan acak dan memeriksa invariant setelah tiap panggilan.
Yang baru dibanding `foundry-workflow` (skill yang sudah dimiliki — hanya dasar
handler + ghost variable):

| Fitur | Keterangan |
|---|---|
| `afterInvariant()` | Hook yang dicek SEKALI di akhir tiap run (bukan tiap panggilan). Untuk cek agregat/end-of-run yang mahal. Tanda tangan harus persis `afterInvariant()`, satu per kontrak test, perubahan state di dalamnya tidak disimpan. |
| `check_interval` (v1.7+) | Trade-off presisi vs kecepatan di campaign dalam: 0 = cek panggilan terakhir saja, 1 = tiap panggilan, N = tiap N panggilan + selalu panggilan terakhir. Risiko: bug yang merusak lalu memulihkan invariant di antara cek bisa lolos. |
| `max_time_delay` / `max_block_delay` (v1.7+) | Fuzz JARAK WAKTU/BLOK antar panggilan — bukan hanya urutan panggilan. Kunci untuk bug yang bergantung pada `block.timestamp` / `block.number`: vesting, auction, TWAP, cooldown, **akrual bunga**. |
| Optimization mode | Bila fungsi `invariant_*` mengembalikan `int256` (bukan assert), Foundry beralih dari "cari kegagalan" ke "maksimalkan nilai ini". Cocok untuk worst-case slippage, imbalance maksimum, rounding error terbesar. Pakai `seed` tetap agar hasil reproducible. |
| `targetSelector` / `excludeSelector` | Batasi fuzz ke selector tertentu saja, atau kecualikan fungsi debug. |
| Call summary | Handler menghitung panggilan per selector; `invariant_*` yang memanggil `callSummary()` menampilkan distribusi — bukti semua fungsi benar-benar teruji. |

### 1.2 SKILL.md `invariant-testing` — mystic0xx (dibaca penuh + audit keamanan)

Sumber: https://github.com/mystic0xx/awesome-solidity-smart-contracts-skills
(`skills/invariant-testing/SKILL.md`, 4.633 byte, 98 baris). Lisensi repo MIT
(terverifikasi via GitHub API, 16 Nov 2026). Repo yang sama dengan skill batch 5–6
yang sudah diadopsi (`fixed-point-rounding`, `oracle-safety`, dll).

Isi: prinsip invariant break sebagai sumber utama exploit high-severity; pola
handler + ghost variable (contoh Pool: `ghost_depositedSum`, invariant solvency
`token.balanceOf(pool) >= totalDeposits()`); `fail_on_revert` (mulai `true` lalu
`false` bila sudah ketat); checklist adopsi; referensi Foundry Book + Cyfrin §5.

**Audit keamanan (checklist skill-security-auditor, 16 Nov 2026) — verdict: PASS.**

| Pemeriksaan | Hasil |
|---|---|
| Grep pola terlarang (`*_API_KEY`, `PRIVATE_KEY`, `SEED_PHRASE`, `curl \| sh/bash`, `rm -rf /`, `requests.post`, `urllib`, `socket.connect`, `os.system`, `eval(`, `exec(`, `pickle.loads`, `yaml.load`, "Ignore previous instructions", "You are now", "Skip safety checks", `sudo`, `chmod 777`, referensi Claude Code, alias model opus/sonnet/haiku) | **0 temuan** (grep exit 1) |
| Karakter zero-width / BOM (cek Python byte-level) | TIDAK ADA |
| Komentar HTML berisi direktif | TIDAK ADA |
| Skrip / dependensi / biner / symlink / file tersembunyi | TIDAK ADA — 1 file `.md` saja |
| Frontmatter | Ada (`name: invariant-testing` + deskripsi) |
| Catatan | Menyebut Echidna/Medusa/Halmos sebagai ALTERNATIF di bagian "Alternatives" (prosa, tanpa instruksi install/adopsi). Bukan temuan. Per pengecualian lisensi Mas 16 Nov 21:13 WIB, metodologi tool AGPL/GPL/CC-BY-SA BOLEH dipelajari + ditulis-ulang dengan kata sendiri, TANPA mengadopsi kode dan TANPA menginstal tool-nya. |

**Keputusan:** audit PASS. Skill ini LAYAK diadopsi sebagai custom skill (adaptasi
Bahasa Indonesia, tanpa referensi Claude Code — sudah tidak ada) — TETAPI adopsi
formal menunggu verifikasi main chat sesuai aturan misi. File audit mentah di
`/tmp/invariant-skill-audit/SKILL.md` (bukan di repo; hanya salinan audit).

### 1.3 Verifikasi fitur di Foundry terinstal

`forge 1.9.0` (commit 6056c584, build 2026-11-02) — `max_time_delay`,
`max_block_delay`, `check_interval`, `afterInvariant()` dan optimization mode
semuanya tersedia (terverifikasi lewat Foundry Book v1.7+ + perilaku test di bawah:
time-delay TERBUKTI bekerja — lihat sekuens gagal versi buggy yang berisi
`warp=46238`, `warp=9202`, `warp=222276` detik antar panggilan).

## 2. PRACTICE — protokol lending lokal + invariant test

**Lokasi:** `test-lab/invariant-lending/` (di repo ini).
**Semua kode kontrak ditulis sendiri untuk lab ini (MIT).** Bukan kode produksi
orang lain. Satu-satunya dependensi eksternal: `forge-std` (MIT OR Apache-2.0)
— disalin dari copy lokal yang sudah dipakai di hunt Sparklend
(`research/spark-bugbounty/poc/h1-h10/lib/forge-std`), tanpa fetch baru.

### 2.1 Protokol: `src/SimpleLending.sol` (benar) + `src/SimpleLendingBuggy.sol`

Model minimal satu aset (collateral SEKALIGUS aset pinjaman), LTV 75%, bunga
simple interest ~5% APR (`RATE_PER_SECOND = 1585489599`), diakru lazy di awal
setiap fungsi mutasi. Fungsi: `deposit`, `withdraw` (cek health factor),
`borrow` (cek LTV), `repay`.

**Perbedaan SATU-SATUNYA antara versi benar dan buggy — fungsi `accrue()`:**

```solidity
// VERSI BENAR: bunga dihitung PER-PEMINJAM, totalBorrows bertambah dari
// JUMLAH bunga per-peminjam yang sama persis -> sum(debtOf) == totalBorrows.
for (uint256 i = 0; i < borrowers.length; i++) {
    address u = borrowers[i];
    uint256 interest = (debtOf[u] * RATE_PER_SECOND * dt) / 1e18;
    if (interest > 0) { debtOf[u] += interest; totalBorrows += interest; }
}

// VERSI BUGGY: bunga hanya ke totalBorrows (rumus global), debtOf tak disentuh.
uint256 interest = (totalBorrows * RATE_PER_SECOND * dt) / 1e18;
totalBorrows += interest;
```

Dampak bug (pola NYATA — mismatch akrual global vs per-user): (1) `sum(debtOf) <
totalBorrows` begitu waktu berlalu + ada utang; (2) cek health-factor memakai
utang usang (lebih kecil) -> over-borrow dimungkinkan; (3) `repay()` dibatasi
`debtOf` (usang) -> bunga terakru tidak pernah bisa dilunasi.

### 2.2 Handler + ghost variables: `test/LendingInvariant.t.sol`

Handler `LendingHandler` adalah satu-satunya permukaan yang di-fuzz: 3 aktor
tetap, fungsi `deposit / withdraw / borrow / repay / warpTime`, input dibatasi
(`bound`) ke state valid. Ghost variables: `ghost_collateralSum`,
`ghost_debtSum`, `ghost_interestSum`, `ghost_collateral[actor]`,
`ghost_debt[actor]` — ghost mereplikasi akrual bunga per-aktor dengan rumus
yang sama persis, pada timestamp yang sama.

**Keputusan desain kunci (ditemukan lewat kegagalan — lihat §4):** ghost
di-akru SEBELUM tiap aksi, dan tiap aksi di-PRE-CHECK dengan state ghost
sehingga panggilan ke pool SELALU sukses. Pre-check memakai helper view
`_debtAfterAccrual()` (nilai utang pasca-akrual tanpa mengubah state).
Tanpa ini, bila handler return dini SETELAH `_accrueGhost()` (mis. borrow
gagal karena LTV), ghost maju sementara akrual pool ikut ter-rollback oleh
revert -> false positive.

### 2.3 Invariant yang diuji (6 + 1 hook)

| Invariant | Arti | Status versi benar | Status versi buggy |
|---|---|---|---|
| `invariant_debtAccounting` | Σ `debtOf` == `totalBorrows` | PASS | **FAIL (tripwire)** |
| `invariant_ghostDebtMatches` | `ghost_debtSum` == Σ `debtOf` | PASS | **FAIL (tripwire)** |
| `invariant_collateralAccounting` | Σ `collateralOf` == `totalCollateral` | PASS | PASS |
| `invariant_ghostCollateralMatches` | `ghost_collateralSum` == `totalCollateral` | PASS | PASS |
| `invariant_solvency` | `balance + totalBorrows >= totalCollateral` | PASS | PASS |
| `invariant_poolBalanceIdentity` | `balance == collateral + interest - debt` (ghost) | PASS | PASS |
| `afterInvariant()` | cek agregat akhir tiap run (identitas saldo) | PASS | PASS |
| `invariant_callSummary` | distribusi panggilan per selector | PASS | PASS |

**Invariant yang SENGAJA TIDAK dipakai:** `health factor >= 1 untuk semua
peminjam`. HF sah turun di bawah 1 seiring bunga terakru (itu wilayah
likuidasi, bukan bug) — assert ini adalah kesalahan pemula yang umum.

**Konfigurasi** (`foundry.toml`): `runs = 128`, `depth = 100`,
`fail_on_revert = false`, `max_time_delay = 86400` (1 hari),
`max_block_delay = 100`, `solc = 0.8.24`.

## 3. TEST — hasil (semua dijalankan 16 Nov 2026, Foundry 1.9.0)

### 3.1 Versi benar — LULUS

```
forge test --match-contract LendingInvariantTest
Suite result: ok. 1 passed; 0 failed — 8.17s
(128 runs x 100 depth = 12.800 panggilan; 0 revert)
Distribusi panggilan: deposit 2622, borrow 2516, withdraw 2576,
repay 2529, warpTime 2557 — semua fungsi teruji merata.
```

Campaign dalam (`FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=200`,
51.200 panggilan): **LULUS, 34,32 detik.**

### 3.2 Versi buggy — GAGAL dengan benar (bukti test bekerja)

```
forge test --match-contract LendingBuggyInvariantTest
[FAIL: sum debtOf != totalBorrows: 11047 != 11050] invariant_debtAccounting
[FAIL: ghost debt != sum debtOf: 11050 != 11047] invariant_ghostDebtMatches
2/7 invariants broken — 5 lainnya PASS (sesuai prediksi)
Sekuens (sudah di-shrink Foundry, 3 panggilan):
  deposit(...)  warp=46238s
  borrow(...)   warp=9202s
  borrow(...)   warp=222276s
```

Time-delay-lah yang memicu kegagalan: tanpa `max_time_delay` + `warpTime`,
bug ini tidak muncul (akrual butuh waktu berlalu). Inilah tepatnya kelas bug
yang dicari pass 1: hanya muncul dari URUTAN + WAKTU, bukan satu panggilan.

### 3.3 Demo deterministik — angka besar (bukan dust fuzz)

`AccrualDivergenceTest`: deposit 100 ether, pinjam 50 ether, warp 30 hari,
picu akrual:

| | Σ `debtOf` | `totalBorrows` | Bunga |
|---|---|---|---|
| BENAR | 50,205479452030400000 ether | 50,205479452030400000 ether | 0,2054794520304 ether — cocok TEPAT |
| BUGGY | 50 ether (tak pernah terakru) | 50,2054794520304 ether | 0,2054794520304 ether TERSEMBUNYI |

Full suite: 3 passed, 1 failed — yang gagal HANYA test versi buggy, sesuai desain.

## 4. Pelajaran — 3 kesalahan desain test SENDIRI yang ditemukan dan diperbaiki

Semua ditemukan karena versi BENAR sempat gagal di run pertama (3/6 invariant
rusak). Ini pelajaran yang sama berharganya dengan hasil test:

1. **Ghost mendahului pool saat early return.** Handler memanggil
   `_accrueGhost()` lalu return dini (borrow gagal LTV / withdraw gagal HF)
   tanpa memanggil pool. Akrual pool ikut ter-rollback oleh revert, ghost
   tidak. Perbaikan: pre-check dengan helper view `_debtAfterAccrual()`,
   `_accrueGhost()` hanya bila pool benar-benar akan dipanggil.
2. **Assert solvabilitas yang salah.** `balance <= totalCollateral` SALAH:
   bunga yang dibayar peminjam adalah token yang masuk ke pool, jadi saldo
   pool sah melebihi total titipan. Perbaikan: ganti dengan identitas saldo
   eksak `balance == collateral + interest - debt`.
3. **Underflow di `afterInvariant`.** `collateral - (debt - interest)`
   underflow bila bunga yang sudah dilunasi membuat `debt < interest`.
   Perbaikan: susun ulang jadi `collateral + interest - debt`
   (selalu aman karena `debt <= 0.75*collateral + interest`).

## 5. Batasan

- 1 protokol toy, 1 kelas bug (akrual bunga). Belum diuji pada protokol nyata.
- Handler 3 aktor tetap; belum multi-actor acak / `targetSender`.
- Belum memakai optimization mode (`invariant_*` return `int256`) dan
  `check_interval` — dicatat untuk latihan berikut.
- `accrue()` toy iterasi array borrowers (gas tak terbatas) — tidak layak
  produksi; hanya untuk lab.
- Build mengeluarkan 2 warning lint (reentrancy-no-eth, erc20-unchecked-transfer)
  pada kode toy + mock token — sengaja tidak diperbaiki (di luar scope lab,
  token mock mengembalikan bool dan tidak memakai ETH).
- RPC publik `eth.llamarpc.com` DOWN dari sandbox ini (HTTP 525) saat pengetesan
  16 Nov 2026 — untuk fork test dipakai `ethereum.publicnode.com` /
  `1rpc.io/eth` / `eth.drpc.org` (ketiganya merespons `eth_blockNumber` OK,
  blok 0x19342d8). Catatan ini relevan untuk item #2 dan #3.

## 6. Status & langkah berikut

- [x] STUDY Foundry Book + SKILL.md mystic0xx — selesai.
- [x] Audit keamanan SKILL.md — **PASS** (0 temuan). Adopsi formal menunggu
      verifikasi main chat.
- [x] PRACTICE — protokol lending lokal + handler + ghost + time-delay — selesai.
- [x] TEST — versi benar LULUS (12.800 + 51.200 panggilan); versi buggy GAGAL
      dengan benar (2 tripwire, sekuens ter-shrink) + demo deterministik — selesai.
- [ ] INTEGRATE — jadikan pola ini template tetap untuk audit protokol
      berikutnya (handler + ghost + time-delay sebagai default, bukan opsi).
- Berikutnya (pass 2 fase A): #3 DeFiHackLabs, #6 DVD baseline.
