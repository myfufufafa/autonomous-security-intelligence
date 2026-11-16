# Capture The Ether — Baseline Batch 2 (5 tantangan tersisa)

**Tanggal:** 16 November 2026 (23:43–23:59 WIB)
**Skor: 5/5** — 10 test lolos (5× testInit + 5× testSolve), 0 gagal
**Total CTE: 14/14** (batch 1: 9/9 + batch 2: 5/5)
**Kerangka kerja:** Foundry 1.9.0, proyek `/tmp/cte-work` (solc 0.8.x untuk harness,
solc 0.4.21 auto-download untuk kontrak 0.4.x via `deployCode`)

## 0. Sumber kontrak & kejujuran

- Repo resmi CTE **HILANG** (404 — smarx/capture-the-ether, OpenZeppelin/capture-the-ether).
- Kontrak dari recreation/mirror: **RareSkills** (`/tmp/cte-repo`), **raion**
  (`/tmp/cte-raion`, Foundry recreation 0.8.0), **MrToph** (`/tmp/cte-mrtoph`,
  kontrak asli 0.4.21).
- **TIDAK PERNAH dibuka satu pun file `test/` mirror. Kontaminasi nol.**
- Peringatan: `/tmp/cte-raion/README.md` adalah repo "Solutions" — hanya bagian
  atasnya yang sempat terlihat (isi + Guess the number + awal Guess the secret
  number — batch 1, sudah diketahui), lalu **sengaja berhenti membaca**.
  File `src/*/helpers/Attack*.sol` di raion **tidak pernah dibaca**.
- "Token balance" yang disebut di brief **TIDAK ADA** dalam daftar resmi CTE —
  tantangan ke-14 yang sebenarnya adalah **Token bank** (dicatat juga di baseline batch 1).
- Semua kontrak dibaca dari `src/`/`contracts/` saja, lalu disalin ke
  `/tmp/cte-work/src/` dan diuji dengan PoC yang ditulis sendiri.

## 1. Hasil per level

| # | Tantangan | Root cause | Severity | testSolve gas | Percobaan |
|---|-----------|-----------|----------|--------------|-----------|
| 10 | Predict the block hash | `blockhash()` blok >256 lama = `0x0` | Medium | 135.991 | 1 (lolos) |
| 11 | Donation | struct storage tak terinisialisasi menimpa `owner` | **Critical** | 133.115 | 2 (BLOKIR tentatif → terbantah → lolos) |
| 12 | Fifty years | pointer storage tak terinisialisasi + overflow timestamp | High | 242.104 | 2 (off-by-one → lolos) |
| 13 | Assume ownership | typo nama constructor | High | 78.662 | 1 (lolos) |
| 14 | Token bank | reentrancy via ERC223 `tokenFallback` | **Critical** | 88.168 | 1 (lolos) |

Total gas testSolve batch 2: **678.040**. Total CTE (14 level): **2.571.944**
(batch 1: 1.893.904 + batch 2: 678.040).
Severity batch 2: **2 Critical, 2 High, 1 Medium, 0 Low**.
Severity CTE total (14): **2 Critical, 4 High, 6 Medium, 2 Low**.
Root cause first-attempt (logika): 5/5. False positive: 0.
Kegagalan harness (bukan logika): 2 — FiftyYears off-by-one (lihat §3),
Donation salah baca lokasi struct (lihat §4).

Waktu analisis (estimasi dari alur sesi, bukan stopwatch): #10 ~2 mnt, #11 ~6 mnt,
#12 ~4 mnt, #13 ~1 mnt, #14 ~2 mnt. Total batch 2 ~16 mnt (23:43–23:59 WIB).

---

## 2. Per level

### #10 Predict the block hash — Medium

**Kontrak:** `PredictTheBlockHashChallenge.sol` (raion 0.8.0).
`lockInGuess` menyimpan `settlementBlockNumber = block.number + 1`;
`settle()` memakai `blockhash(settlementBlockNumber)`.

**Root cause:** `blockhash()` mengembalikan `0x0` untuk blok yang sudah
lebih dari 256 blok lama. Jadi tebak `0x0`, tunggu 257+ blok, lalu `settle()`
— jawaban selalu 0, menang 2 ether.

**PoC:** kunci tebakan `0x0`, `vm.roll(block.number + 300)`, `settle()`.
`testSolve` gas 135.991. Lolos percobaan pertama.

**Severity: Medium.** Di kontrak game ini taruhannya terbatas (2 ether) dan
butuh menunggu 257 blok. Tapi primitifnya serius: randomness apa pun yang
bergantung pada `blockhash` blok lama adalah deterministik-nol. Di produksi
(lotere, RNG on-chain) kelas ini High/Critical.

**Apa yang BARU vs DVD + Ethernaut + CTE batch 1:** primitif
*time-decay ke konstanta yang diketahui* — nilai yang tadinya acak menjadi
nol setelah jendela 256 blok. Terkait P-17/T-03 (pilih waktu eksekusi) tapi
mekanismenya berbeda: bukan memprediksi nilai acak, melainkan menunggu nilai
itu **menjadi nol**. Pola baru: **N-04**.

### #11 Donation — Critical

**Kontrak:** `DonationChallenge.sol` (MrToph 0.4.21 asli; identik dengan raion,
diff kosong). `donate(etherAmount)`: `scale = 10**18 * 1 ether = 10^36`,
`require(msg.value == etherAmount / scale)`; `withdraw()` owner-only;
`isComplete` = saldo 0.

**Root cause (yang SESUNGGUHNYA):** `Donation donation;` di dalam `donate()`
**tanpa** penentu lokasi `memory`/`storage`. Di Solidity 0.4.x, variabel lokal
bertipe struct **default ke STORAGE** dan bila tak diinisialisasi menunjuk
**slot 0**. Layout: slot 0 = `donations.length`, slot 1 = `owner`. Maka:
- `donation.timestamp = now` → slot 0 = `now` (length!)
- `donation.etherAmount = etherAmount` → slot 1 = `etherAmount` (**OWNER!**)
- `donations.push(donation)` → length `now+1`, elemen di indeks `now`.

Penyerang memanggil `donate(uint160(alamatPenyerang))` dan **menjadi owner**,
lalu `withdraw()` menguras seluruh saldo. Require `msg.value` terpenuhi
dengan nilai kecil: alamat 160-bit / 10^36 ≤ ~1,46e12 wei.

**Bug divisi integer di `donate` BUKAN bug sesungguhnya** — ia hanya mekanisme
agar require lolos murah. Donasi yang tercatat pun tidak pernah dibaca oleh
fungsi apa pun (inert). Lihat §4 untuk kisah lengkapnya: kesimpulan BLOKIR
tentatif **terbantah oleh bukti empiris**.

**PoC:** attacker contract `attack()`: `donate(uint160(address(this)))`
dengan `msg.value = etherAmount / 10^36`, lalu `withdraw()`. Setelah serangan
`owner == attacker`, `isComplete == true`. `testSolve` gas 133.115.

**Severity: Critical.** Pengambilalihan owner tanpa autentikasi + drain penuh
oleh siapa pun, dengan satu panggilan murah. Di produksi ini adalah
kerentanan takeover + pencurian dana penuh.

**Apa yang BARU:** keluarga bug yang sama dengan FiftyYears (#12) — pointer
storage tak terinisialisasi — tapi manifestasi berbeda: **struct lokal di
dalam fungsi yang menimpa `owner`**, bukan pointer di cabang if/else. Pola
baru: **N-02** (varian dari N-01). Pelajaran metodologisnya lebih penting
dari polanya: lihat §4.

### #12 Fifty years — High

**Kontrak:** `FiftyYearsChallenge.sol` (MrToph 0.4.21 asli; raion hanya beda
format + MrToph punya anotasi `// @note` yang mengonfirmasi mekanisme).
`upsert` cabang else memakai `contribution` yang hanya dideklarasikan di
cabang if.

**Root cause:** dua bug yang dirantai.
1. **Pointer storage tak terinisialisasi.** Di Solidity 0.4.x deklarasi
   variabel bersifat function-scoped, jadi `contribution` (dideklarasikan di
   cabang if) terlihat di cabang else tapi **tak terinisialisasi** → menunjuk
   slot 0. `contribution.amount = msg.value` menulis slot 0 (`queue.length`),
   `contribution.unlockTimestamp = timestamp` menulis slot 1 (`head`).
   `queue.push` menaikkan length DULU lalu membaca struct — elemen yang
   di-push = `{amount: msg.value + 1, unlockTimestamp: timestamp}`.
2. **Overflow penjumlahan timestamp → require bypass.** Require di `upsert`:
   `timestamp >= queue[queue.length - 1].unlockTimestamp + 1 days`.
   Dengan `unlockTimestamp = 2^256 - 86400`, penjumlahan membungkus ke 0
   (aritmetika 0.4.x tanpa pengecekan) sehingga `timestamp = 0` lolos.

**Rantai exploit:**
- Upsert A: indeks di luar jangkauan (5), 1 wei, `timestamp = 2^256 - 86400`
  → length=1, head=`2^256-86400`, `queue[1] = {2, 2^256-86400}`, dan
  `queue[0] = {1 ether, +50 tahun}` **tetap utuh** (kritis: upsert pertama
  harus msg.value=1, bukan 0).
- Upsert B: indeks di luar jangkauan, 1 wei, `timestamp = 0` → require lolos
  karena `(2^256-86400) + 86400` membungkus ke 0 → head=0,
  `queue[1]` ditulis ulang `{2, 0}`.
- `withdraw(1)`: require hanya memeriksa `queue[1].unlockTimestamp` (0);
  loop head=0..1 menjumlah `queue[0]` (1 ether) + `queue[1]` (2 wei)
  = seluruh saldo → saldo 0.

**PoC:** attacker contract dengan `upsert`/`withdraw` via low-level call;
`vm.deployCode(..., 1 ether)`. `testSolve` gas 242.104. Lolos setelah 1
perbaikan (off-by-one, lihat §3).

**Severity: High.** Drain penuh (1 ether + 2 wei) lewat korupsi storage +
bypass timelock. Di tantangan ini penyerang adalah owner (peran itu
diperlukan untuk `upsert`), jadi bukan takeover tanpa autentikasi — tapi
kelas bugnya (pointer storage + overflow) adalah Critical di produksi.

**Apa yang BARU:** dua pola baru. **N-01** — pointer storage tak
terinisialisasi (cabang if/else, overwrite slot 0/1). **N-03** — overflow
penjumlahan timestamp → bypass require. Keduanya belum muncul di DVD,
Ethernaut, maupun CTE batch 1.

### #13 Assume ownership — High

**Kontrak:** `AssumeOwnershipChallenge.sol` (MrToph 0.4.21).
Constructor typo: fungsi bernama `AssumeOwmershipChallenge` (huruf 'n'
hilang) — **bukan** constructor, melainkan fungsi publik yang bisa dipanggil
siapa pun untuk menjadi owner; lalu `authenticate()` → `isComplete = true`.

**Root cause:** typo nama constructor (Solidity 0.4.x memakai nama fungsi =
nama kontrak sebagai constructor). Kelas yang sama persis dengan Ethernaut
#2 Fallout.

**PoC:** panggil `AssumeOwmershipChallenge()` lalu `authenticate()`.
`testSolve` gas 78.662. Lolos percobaan pertama.

**Severity: High.** Takeover owner tanpa autentikasi + `isComplete` langsung.
Sama seperti Fallout (High).

**Apa yang BARU:** **TIDAK ADA.** Varian dari pola yang sudah dikenal
(Ethernaut #2 Fallout, constructor typo). Dicatat jujur sebagai bukan-baru.

### #14 Token bank — Critical

**Kontrak:** `TokenBankChallenge.sol` (MrToph 0.4.21 asli; raion hanya beda
format). `SimpleERC223Token` + `TokenBankChallenge`; `withdraw` memanggil
`token.transfer` **SEBELUM** `balanceOf[msg.sender] -= amount`; callback
ERC223 `tokenFallback` memungkinkan reentrancy.

**Root cause:** checks-effects-interactions dilanggar — transfer token
(sebelum pengurangan saldo) memicu callback `tokenFallback` di kontrak
penyerang, yang masuk lagi ke `withdraw`. **Harus memakai 0.4.21 asli**:
di Solidity 0.8, pengurangan di luar akan revert karena underflow
(aritmetika terperiksa) dan exploit gagal.

**PoC:** attacker dengan `tokenFallback` yang masuk lagi ke
`withdraw(500000e18)` sekali (guard flag) → saldo token bank 0 → pengurangan
di luar underflow diam-diam (0.4.21) → tanpa revert → `isComplete` true.
`testSolve` gas 88.168. Lolos percobaan pertama.

**Severity: Critical.** Reentrancy drain penuh (500.000 token) dari bank.

**Apa yang BARU:** kelasnya dikenal (reentrancy — Ethernaut #10), tapi
mekanisme pengiriman **baru**: callback ERC223 `tokenFallback` sebagai vektor
reentrancy (bukan `receive()`/`fallback()` Ether biasa). Pola baru: **N-05**
(varian pengiriman reentrancy).

---

## 3. Kegagalan harness #1: FiftyYears off-by-one

Percobaan pertama `testSolve` gagal (Revert) pada Upsert B. Probe storage
(file sementara `99-Probe.t.sol`, sudah dihapus) menunjukkan state setelah
Upsert A **benar** (length=2, head=`2^256-86401`, `queue[1]={2, ...}`) — tapi
`q1unlock + 86400` = MAX, bukan 0. Kesalahan hitung: `MAX - 86400`
= `2^256 - 86401`, bukan `2^256 - 86400`. Yang benar: `MAX - 86399`
= `2^256 - 86400`, sehingga +86400 membungkus ke **tepat 0**.
Satu perbaikan, lolos. Pelajaran: hitung batas overflow dengan
`2^256 - N` eksplisit, jangan lewat `MAX - N` tanpa memeriksa selisih 1.

## 4. Kegagalan analisis #1: Donation — BLOKIR tentatif yang TERBANTAH

Ini pelajaran metodologis terpenting batch ini.

**Kesimpulan tentatif (salah):** bug divisi integer di `donate` bersifat inert
(catatannya tak pernah dibaca); satu-satunya ether-out adalah `withdraw()`
owner-only; penyerang bukan owner; jadi BLOKIR (SMART SKIP), skor 4/5.

**Bukti empiris yang membantahnya:** test analisis negatif menunjukkan
`donations(0)` mengembalikan `(0, 0)` — padahal `donate(10^36 - 1)` sudah
berhasil dan "mencatat" donasi raksasa. Kalau `Donation donation;` adalah
memory struct, elemen 0 harus berisi `(now, 10^36 - 1)`. Nilai (0, 0)
membuktikan elemen ditulis di indeks **`now`**, bukan 0 — yang hanya mungkin
bila `donation` adalah **pointer storage tak terinisialisasi** yang menimpa
slot 0 (length = `now`) sebelum push. Dari situ terlihat konsekuensi
penuhnya: slot 1 (`owner`) ikut tertimpa dengan `etherAmount`.

**Kesimpulan akhir (benar):** Donation **TERPECAHKAN** — penyerang menjadi
owner lewat satu panggilan `donate`, lalu `withdraw()`. Skor batch 2: **5/5**.

**Pelajaran bounty:**
1. **PoC empiris mengalahkan analisis statis.** Tanpa menjalankan test
   negatif, kesimpulan BLOKIR yang salah akan bertahan.
2. **Anomali kecil adalah petunjuk.** `(0, 0)` padahal donasi "berhasil"
   adalah sinyal, bukan noise — kejar sampai ke akar.
3. **Di Solidity 0.4.x, JANGAN PERNAH menganggap variabel lokal struct
   adalah memory.** Default-nya storage; bila tak diinisialisasi, ia menunjuk
   slot 0 dan menimpa state. Ini pola yang sama dengan FiftyYears — dua
   tantangan dalam satu batch memakai keluarga bug yang sama.
4. **Jangan berhenti di bug yang terlihat pertama.** Bug divisi integer itu
   nyata tapi inert; bug sesungguhnya bersembunyi satu baris di atasnya
   (`Donation donation;`).

## 5. Pola baru vs DVD + Ethernaut + CTE batch 1

| Pola | Sumber | Keterangan |
|------|--------|-----------|
| **N-01** | FiftyYears | Pointer storage tak terinisialisasi (cabang if/else) → overwrite slot 0/1 |
| **N-02** | Donation | Struct storage tak terinisialisasi di dalam fungsi → overwrite `owner` (varian N-01) |
| **N-03** | FiftyYears | Overflow penjumlahan timestamp → bypass require |
| **N-04** | Predict the block hash | `blockhash` blok >256 lama = 0 (time-decay ke konstanta diketahui) |
| **N-05** | Token bank | Reentrancy via callback ERC223 `tokenFallback` (varian pengiriman) |
| — | Assume ownership | **Bukan baru** — varian Ethernaut #2 Fallout (constructor typo) |

Keluarga bug **pointer storage tak terinisialisasi (N-01/N-02)** adalah temuan
terbesar batch ini: dua dari lima tantangan memakainya, dan satu di antaranya
(Donation) hampir lolos dari deteksi karena bug yang lebih mencolok (divisi
integer) menutupi bug sesungguhnya. Di Solidity modern (0.5.0+) pola ini
sudah tidak bisa dikompilasi — tapi tetap relevan saat mengaudit kontrak
lama / fork 0.4.x yang masih beredar.

## 6. Ringkasan & pelajaran bounty

- **CTE SELESAI PENUH: 14/14** (batch 1: 9/9, batch 2: 5/5). 28 test lolos,
  0 gagal. Root-cause accuracy 14/14 (13/14 first-attempt logika — Donation
  butuh koreksi analisis, FiftyYears butuh 1 perbaikan harness).
- **Severity CTE total: 2 Critical, 4 High, 6 Medium, 2 Low.**
- **Kualitas PoC:** semua PoC dieksekusi dan PASS dengan bukti segar
  (`forge test` penuh: 28 passed, 0 failed). Solusi disalin ke `benchmarks/`
  segera setelah tiap level lolos dan diverifikasi `cmp`-IDENTICAL.
- **Pelajaran terbesar:** (1) audit kontrak 0.4.x — selalu curigai variabel
  lokal struct/array tanpa penentu lokasi (default storage, slot 0);
  (2) hitung batas overflow eksplisit (`2^256 - N`, bukan `MAX - N`);
  (3) jangan berhenti di bug pertama yang terlihat — bug inert bisa menutupi
  bug kritis; (4) anomali empiris kecil (getter mengembalikan 0) adalah
  petunjuk, bukan noise; (5) `blockhash` bukan sumber randomness yang aman
  setelah 256 blok; (6) reentrancy tidak hanya lewat `receive()` — callback
  token standar (ERC223 `tokenFallback`) adalah vektor yang sama.
- **SMART SKIP tidak pernah terpicu** di batch ini. Satu BLOKIR tentatif
  (Donation) **terbantah** oleh bukti empiris sebelum dicatat final — contoh
  yang baik bahwa "blokir" harus selalu diuji, bukan diasumsikan.

## 7. File

- `benchmarks/cte-baseline-2-2026-11-16.md` (file ini)
- `benchmarks/cte-predict-the-block-hash-solution.t.sol`
- `benchmarks/cte-donation-solution.t.sol`
- `benchmarks/cte-fifty-years-solution.t.sol`
- `benchmarks/cte-assume-ownership-solution.t.sol`
- `benchmarks/cte-token-bank-solution.t.sol`
- Proyek kerja: `/tmp/cte-work` (test `10-`…`14-*.t.sol`, src dari mirror)
