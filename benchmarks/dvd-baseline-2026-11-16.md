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
**Update fase D (16 Nov 2026 ~21:54 WIB): tantangan #4 Side-Entrance,
#5 The Rewarder, #6 Selfie SELESAI — skor 6/13.** 7 tantangan tersisa.
File test Unstoppable di full port juga sudah diisi exploit #1 (sebelumnya
kosong — solusinya hanya ada di proyek minimal); keenam tantangan kini
lolos di SATU tempat yang sama (`/tmp/dvd`, `forge test` 6/6 PASS).

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
**6/13 tantangan selesai** (Unstoppable #1, Naive Receiver #2, Truster #3,
Side-Entrance #4, The Rewarder #5, Selfie #6).

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
- [x] Kerjakan tantangan #4 side-entrance → #5 the-rewarder → #6 selfie
  — **SELESAI 16 Nov 2026 ~21:54 WIB (fase D, lihat §9–§11)**.
- [ ] Kerjakan tantangan #7–#13, catat per tantangan: akurasi,
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

## 9. Tantangan #4 — Side-Entrance (fase D, 16 Nov 2026 ~21:53 WIB)

**Deskripsi:** pool lending ETH 1.000 ETH, flash loan gratis. Tujuan:
kuras seluruh ETH pool ke attacker.

**Kontrak yang dibaca (sebelum solve):**
`src/Contracts/side-entrance/SideEntranceLenderPool.sol` (47 baris),
test `SideEntrance.t.sol` (syarat sukses: saldo pool 0, saldo attacker
bertambah).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function flashLoan(uint256 amount) external {
    uint256 balanceBefore = address(this).balance;
    if (balanceBefore < amount) revert NotEnoughETHInPool();
    IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
    if (address(this).balance < balanceBefore) {
        revert FlashLoanHasNotBeenPaidBack();
    }
}
```

Satu cacat: flash loan hanya mengecek saldo ETH pool kembali seperti
semula — ia TIDAK mengecek BAGAIMANA saldo itu kembali. Pool punya
fungsi `deposit()` yang mengkredit `balances[msg.sender]` untuk ETH apa
pun yang dikirim, dan `withdraw()` yang membayar kembali saldo tercatat
itu. Jadi di dalam callback `execute()`, penyerang cukup memanggil
`deposit{value: 1.000 ether}()` — ETH pinjaman "kembali" ke pool dan
cek flash loan lolos, padahal ETH itu kini tercatat sebagai DEPOSIT milik
penyerang. Setelah callback, `withdraw()` menariknya keluar secara sah
menurut akuntansi pool. Ini varian lain dari pola yang sama dengan #1:
**cek saldo ≠ cek akuntansi** — saldo kembali, tapi kepemilikan sudah
berpindah.

**Kelas bug:** flash loan yang bisa dilunasi lewat jalur deposit
(akuntansi ganda: satu ETH dihitung sebagai pelunasan DAN sebagai
deposit). Di program bounty nyata: **Critical** — pengurasan total
dana pool, tanpa modal, tanpa privilege.

### Exploit (PoC — kontrak helper, 3 panggilan efektif)

Kontrak `SideEntranceAttacker` (di file solusi): `attack()` memanggil
`pool.flashLoan(1.000 ether)`; callback `execute()` memanggil
`pool.deposit{value: msg.value}()`; kembali di `attack()`,
`pool.withdraw()` lalu teruskan ETH ke attacker EOA.

### Hasil

```
forge test --match-contract SideEntrance
[PASS] testExploit() (gas: 379699)
Suite result: ok. 1 passed; 0 failed — 5.15ms
```

### Metrik

| Metrik | Hasil |
|---|---|
| Akurasi identifikasi bug | **1/1** — root cause benar percobaan pertama, tanpa false positive |
| Root cause | Benar + tepat (cek saldo buta terhadap jalur deposit; ETH pinjaman jadi deposit) |
| Kualitas PoC | Minimal (flash loan → deposit di callback → withdraw) + syarat sukses resmi test |
| Ketepatan severity | Benar: **Critical** — pengurasan total pool, tanpa modal/privilege |
| Waktu analisis | **~4 menit** (baca 1 kontrak + test, tulis helper + exploit) |
| Percobaan gagal | 0 |

**Yang dibawa ke perburuan:** setiap flash loan / callback yang hanya
mengecek "saldo kembali" WAJIB ditanya: "lewat jalur apa saldo itu
kembali, dan apakah jalur itu mengubah kepemilikan?" Pola yang sama
muncul di dunia nyata sebagai: deposit/repay yang berbagi jalur,
`receive()` yang mengkredit saldo, dan akuntansi yang dihitung dua kali.
Perbaikan kanonik: cek pelunasan terhadap `balances` (bukan saldo mentah),
atau kunci `deposit()` selama flash loan berlangsung.

## 10. Tantangan #5 — The Rewarder (fase D, 16 Nov 2026 ~21:53 WIB)

**Deskripsi:** pool reward: deposan DVT mendapat accToken 1:1 + reward
token (100 per ronde 5 hari, dibagi proporsional menurut snapshot).
Empat pengguna sudah deposit 100 DVT masing-masing dan mengambil
reward ronde 2 (25 token tiap orang). Attacker mulai dengan 0 DVT.
Tujuan: rebut hampir seluruh reward ronde 3 (~100 token) dengan
flash loan, lalu akhiri dengan 0 DVT.

**Kontrak yang dibaca (sebelum solve):**
`src/Contracts/the-rewarder/TheRewarderPool.sol` (deposit, withdraw,
distributeRewards, snapshot), `FlashLoanerPool.sol`, `AccountingToken.sol`,
test `TheRewarder.t.sol` (syarat sukses: roundNumber 3, reward tiap
pengguna lama nyaris 0, reward attacker ≈ 100, DVT attacker 0).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function deposit(uint256 amountToDeposit) external {
    if (amountToDeposit == 0) revert MustDepositTokens();
    accToken.mint(msg.sender, amountToDeposit);
    distributeRewards();   // <-- snapshot ronde baru dicatat DI SINI
    ...
}
```

Dua cacat yang bergabung: (1) **urutan operasi**: `deposit()` MINT
accToken dulu, BARU `distributeRewards()` mencatat snapshot ronde baru
— jadi snapshot ronde yang baru dimulai sudah mencakup saldo penyerang;
(2) **snapshot bisa dimanipulasi dengan modal sementara**: flash loan
1.000.000 DVT (seluruh isi FlashLoanerPool) dideposit tepat saat ronde
baru dimulai → snapshot mencatat penyerang 1.000.000 vs total 1.000.400
→ penyerang mendapat ~99,96 dari 100 reward. Lalu withdraw +
lunasi flash loan — modal kembali 0, reward tetap di tangan penyerang.

**Kelas bug:** snapshot manipulation / urutan mint-sebelum-snapshot
(oracle akuntansi yang bisa dipompa dengan modal sementara). Di program
bounty nyata: **High** — pencurian reward pengguna lain (dana nyata,
~100 token), tapi kerugian terbatas pada satu ronde reward, bukan
seluruh dana pool.

### Exploit (PoC — kontrak helper + warp)

Kontrak `RewarderAttacker`: `attack()` memanggil
`flashLoanerPool.flashLoan(1.000.000e18)`; callback `receiveFlashLoan`
approve → `theRewarderPool.deposit(1.000.000e18)` (mint + snapshot +
reward) → `withdraw(1.000.000e18)` → lunasi flash loan; lalu
`attack()` mengirim reward token ke attacker EOA. Sebelumnya,
test melakukan `vm.warp(block.timestamp + 5 days)` agar ronde baru
dimulai.

### Hasil

```
forge test --match-contract TheRewarder
[PASS] testExploit() (gas: 1575208)
Suite result: ok. 1 passed; 0 failed — 14.48ms
```

### Metrik

| Metrik | Hasil |
|---|---|
| Akurasi identifikasi bug | **1/1** — root cause benar percobaan pertama, tanpa false positive |
| Root cause | Benar + tepat (mint dulu baru snapshot + modal flash loan memompa snapshot) |
| Kualitas PoC | Minimal (1 flash loan + deposit + withdraw) + syarat sukses resmi test |
| Ketepatan severity | Benar: **High** — reward pengguna lain dicuri (~100 token), kerugian terbatas satu ronde |
| Waktu analisis | **~5 menit** (baca 3 kontrak + test, tulis helper + warp) |
| Percobaan gagal | 0 |

**Yang dibawa ke perburuan:** setiap mekanisme reward/snapshot WAJIB
ditanya: "kapan snapshot diambil RELATIF terhadap perubahan saldo,
dan bisakah saldo dipompa sementara tepat sebelum snapshot?"
Pola yang sama muncul di dunia nyata sebagai: voting snapshot yang
bisa dipompa flash loan, reward yang dihitung dari saldo sesaat,
dan airdrop berdasarkan snapshot yang bisa dimanipulasi. Perbaikan
kanonik: snapshot DULU baru mint, atau hitung reward dari saldo
rata-rata / saldo pada snapshot ronde SEBELUMNYA.

## 11. Tantangan #6 — Selfie (fase D, 16 Nov 2026 ~21:54 WIB)

**Deskripsi:** pool flash loan 1.500.000 token snapshot DVT (total supply
2.000.000). Governance sederhana: siapa pun yang punya >50% supply
menurut snapshot TERAKHIR bisa mengantre aksi; aksi dieksekusi setelah
delay 2 hari. Pool punya `drainAllFunds(receiver)` yang hanya bisa
dipanggil governance. Tujuan: kuras seluruh token pool ke attacker.

**Kontrak yang dibaca (sebelum solve):**
`src/Contracts/selfie/SelfiePool.sol` (flashLoan + drainAllFunds),
`SimpleGovernance.sol` (queueAction, executeAction, `_hasEnoughVotes`),
test `Selfie.t.sol` (syarat sukses: saldo attacker 1.500.000, saldo pool 0).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function _hasEnoughVotes(address account) private view returns (bool) {
    uint256 balance = governanceToken.getBalanceAtLastSnapshot(account);
    uint256 halfTotalSupply = governanceToken.getTotalSupplyAtLastSnapshot() / 2;
    return balance > halfTotalSupply;
}
```

Dua cacat yang bergabung: (1) **voting power dari snapshot TERAKHIR,
dan siapa pun bisa memicu snapshot baru** — `snapshot()` adalah fungsi
publik tanpa guard; (2) **flash loan memberi mayoritas sementara**:
pinjam 1.500.000 dari 2.000.000 total (75%), snapshot DI DALAM callback
→ saldo snapshot penyerang 1.500.000 > 1.000.000 (setengah supply) →
bisa mengantre aksi apa pun. Aksi yang diantre: governance memanggil
`pool.drainAllFunds(attacker)` — `onlyGovernance` terpenuhi karena
pemanggilnya memang kontrak governance. Lunasi flash loan, tunggu delay
2 hari (`vm.warp`), eksekusi aksi → pool terkuras. Ini adalah chaining
tiga langkah (flash loan → snapshot → governance) — tantangan pertama
yang menuntut lebih dari satu trik.

**Kelas bug:** governance takeover via flash-loan voting power
(snapshot yang bisa dipicu siapa pun + modal sementara = mayoritas
sesaat). Di program bounty nyata: **Critical** — pengurasan total dana
pool + pengambilalihan governance, tanpa modal, tanpa privilege.

### Exploit (PoC — kontrak helper, 3 fase)

Kontrak `SelfieAttacker`: `attack()` memanggil
`pool.flashLoan(1.500.000e18)`; callback `receiveTokens` melakukan
`token.snapshot()` → `governance.queueAction(pool,
drainAllFunds(attacker), 0)` → kembalikan token pinjaman; lalu test
`vm.warp(block.timestamp + 2 days + 1)` dan
`governance.executeAction(actionId)`.

### Hasil

```
forge test --match-contract Selfie
[PASS] testExploit() (gas: 1243928)
Suite result: ok. 1 passed; 0 failed — 5.89ms
```

### Metrik

| Metrik | Hasil |
|---|---|
| Akurasi identifikasi bug | **1/1** — root cause benar percobaan pertama, tanpa false positive |
| Root cause | Benar + tepat (snapshot publik + flash loan mayoritas + governance delay) |
| Kualitas PoC | Minimal (flash loan → snapshot+queue di callback → warp → execute) + syarat sukses resmi test |
| Ketepatan severity | Benar: **Critical** — pengurasan total pool + takeover governance |
| Waktu analisis | **~4 menit** (baca 2 kontrak + test, tulis helper) |
| Percobaan gagal | 0 |

**Yang dibawa ke perburuan:** setiap mekanisme voting/governance
berbasis snapshot WAJIB ditanya: "siapa bisa memicu snapshot, dan
bisakah voting power dipompa sementara tepat sebelumnya?" Pola yang
sama muncul di dunia nyata sebagai: flash-loan governance attack,
snapshot token yang bisa dipicu publik, dan quorum yang dihitung dari
saldo sesaat. Perbaikan kanonik: snapshot hanya oleh kontrak yang
dipercaya / pada waktu tetap, voting power dari snapshot LAMA (bukan
terakhir), atau timelock + quorum yang tidak bisa dipompa dalam satu
transaksi.

## 12. Ringkasan progres benchmark (16 Nov 2026 ~21:54 WIB)

| Tantangan | Root cause | Severity | Waktu analisis | Percobaan gagal | Solusi |
|---|---|---|---|---|---|
| #1 Unstoppable | Akuntansi internal vs saldo aktual | Medium (DoS) | ~5 mnt | 0 | `benchmarks/dvd-unstoppable-solution.t.sol` |
| #2 Naive Receiver | Pemicu pihak ketiga tanpa auth + fee ke korban | High | ~4 mnt | 0 | `benchmarks/dvd-naive-receiver-solution.t.sol` |
| #3 Truster | Arbitrary call sebagai pool → approve → drain | Critical | ~4 mnt | 0 | `benchmarks/dvd-truster-solution.t.sol` |
| #4 Side-Entrance | Cek saldo buta jalur deposit → pinjaman jadi deposit | Critical | ~4 mnt | 0 | `benchmarks/dvd-side-entrance-solution.t.sol` |
| #5 The Rewarder | Mint dulu baru snapshot + flash loan pompa snapshot | High | ~5 mnt | 0 | `benchmarks/dvd-the-rewarder-solution.t.sol` |
| #6 Selfie | Snapshot publik + flash loan mayoritas → takeover governance | Critical | ~4 mnt | 0 | `benchmarks/dvd-selfie-solution.t.sol` |

**Skor: 6/13.** Akurasi identifikasi 6/6 percobaan pertama, 0 false
positive, 0 percobaan gagal. **Verifikasi segar fase D:** keenam test
dijalankan ulang di full port `/tmp/dvd` (`forge test --match-contract`
per tantangan): 6 passed, 0 failed — gas: Unstoppable 99.499,
NaiveReceiver 414.730, Truster 152.510, SideEntrance 379.699,
TheRewarder 1.575.208, Selfie 1.243.928.

**Catatan kejujuran (fase D):** #4–#6 memang menuntut chaining
(#6: flash loan → snapshot → governance), tapi pola dasarnya masih
pola yang dikenal dari literatur (side-entrance = varian cek-saldo
#1; rewarder = snapshot manipulation; selfie = flash-loan governance).
Yang TERASA baru: #6 adalah pertama kalinya exploit butuh tiga
langkah lintas-kontrak + time warp — bukan satu trik. Pengukur yang
sesungguhnya tetap tantangan #7+ (climber, backdoor, free-rider,
compromised, puppet, puppet-v2, safe-miners), yang menuntut chaining
lebih dalam dan pola yang kurang dikenal.
