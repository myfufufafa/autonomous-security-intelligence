# Proposal Integrasi Pola Benchmark ke Skill — Pass 2 fase J

**Tanggal:** 16 November 2026 (misi Skill Evolution, Pass 2 fase J)
**Status:** PROPOSAL SAJA — file skill TIDAK diubah. Main chat yang
menerapkan + memverifikasi (hitung baris, frontmatter, grep pola
terlarang) sebelum menyatakan skill diperbarui. JANGAN klaim skill
sudah diperbarui berdasarkan dokumen ini.
**Sumber:** benchmark yang SUDAH SELESAI dan terverifikasi main chat —
Damn Vulnerable DeFi 13/13 (`benchmarks/dvd-baseline-2026-11-16.md`)
dan Ethernaut 30/30 (`benchmarks/ethernaut-baseline-2026-11-16.md`,
`benchmarks/ethernaut-baseline-11-20-2026-11-16.md`,
`benchmarks/ethernaut-baseline-21-30-2026-11-16.md`). Total **43
tantangan/level terbukti lolos test** (13 Critical DVD + 10 Critical /
15 High / 5 Medium Ethernaut; total Ethernaut 10 Critical, 15 High,
5 Medium). Kejujuran: **29/30 murni + 1 sebagian dibantu** (Ethernaut
#1 Fallback — langkah exploit terlihat di test repo sebelum PoC
sendiri; sisanya dari membaca kontrak + factory saja, tanpa writeup).
Hanya pola yang LOLOS TEST yang masuk proposal ini — tidak ada pola
teori.

## Prinsip penempatan

1. **bounty-hunter** = pola berburu + PoC. Masuk ke Fase 2 (ranking
   prioritas + Tier 1/2/3), Fase 3 (deep dive), atau Fase 4 (PoC).
   Pola yang mengubah CARA berburu masuk sini.
2. **sc-audit** = pola audit. Masuk ke Fase 2 (model ancaman),
   Fase 3 (attack surface), atau Fase 4 (checklist deep review).
   Pola yang mengubah APA YANG DIPERIKSA masuk sini.
3. **invariant-testing** = pola yang bisa difuzz/dibuktikan mesin.
   Masuk ke "Catatan desain" atau "Checklist". Pola yang mengubah
   INVARIANT APA yang ditulis masuk sini.
4. Bila skill sudah mencantumkan pola yang sama secara umum, proposal
   TIDAK menulis ulang — hanya MEMPERKUAT dengan varian + contoh
   konkret dari benchmark (diberi label "PERKUAT").
5. Setiap blok teks diusulkan persis seperti tertulis (Bahasa
   Indonesia). Main chat boleh mengedit redaksi saat menerapkan, tapi
   substansi (pola + contoh + sumber) harus tetap.

## Matriks penempatan (ringkas)

| ID | Pola | Sumber (severity) | Skill → lokasi |
|---|---|---|---|
| P-01 | Oracle spot AMM tanpa TWAP | DVD #11 Puppet (Critical), #12 PuppetV2 (Critical); Eth #11 Dex (Critical), #12 DexTwo (Critical) | bounty-hunter Fase 2 Tier 1 (PERKUAT); sc-audit Fase 4 Oracle (PERKUAT) |
| P-02 | Prediksi alamat CREATE | DVD #13 SafeMiners (Critical); Eth #20 Recovery (High) | bounty-hunter Fase 3 (+butir 10); sc-audit Fase 4 (+butir baru) |
| P-03 | Tabrakan storage proxy | Eth #13 PuzzleWallet (Critical) | sc-audit Fase 4 Upgradeability (PERKUAT); bounty-hunter Fase 2 Tier 2 (PERKUAT) |
| P-04 | Init UUPS tak terlindungi + EIP-6780 | Eth #14 Motorbike (Critical) | sc-audit Fase 4 Upgradeability (+butir); bounty-hunter Fase 4 PoC (+catatan EIP-6780) |
| P-05 | Gerbang gas + extcodesize + serangan dari constructor | Eth #17 GatekeeperOne (High), #18 GatekeeperTwo (High) | sc-audit Fase 4 Access control (PERKUAT); bounty-hunter Fase 2 Tier 1 (PERKUAT) |
| P-06 | Storage packing + private terbaca | Eth #16 Privacy (High), #8 Vault (High), #25 AlienCodex (Critical) | sc-audit Fase 4 (+butir baru); bounty-hunter Fase 1 (+langkah 6) |
| P-07 | Push-payment DoS | Eth #9 King (High), #24 GatekeeperThree (High) | sc-audit Fase 4 Asumsi pemanggilan eksternal (PERKUAT); bounty-hunter Fase 2 Tier 3 (PERKUAT) |
| P-08 | Gas griefing + aturan 63/64 + semantik assert 0.8 | Eth #26 Denial (Medium) | sc-audit Fase 4 Asumsi pemanggilan eksternal (PERKUAT); invariant-testing Catatan desain (+butir) |
| P-09 | Unchecked return value + baca state 2× | Eth #30 Stake (Critical), #27 Shop (High), #15 Elevator (Medium) | sc-audit Fase 4 Asumsi pemanggilan eksternal (PERKUAT) + butir baru; invariant-testing Checklist (+butir) |
| P-10 | Hardcoded offset calldata | Eth #29 Switch (High) | sc-audit Fase 4 (+butir baru) |
| P-11 | Bytecode minimal / baca opcode | Eth #28 MagicNum (Medium) | bounty-hunter Fase 1.5 (+catatan) |
| P-12 | Flash-loan governance + snapshot manipulation | DVD #6 Selfie (Critical), #5 Rewarder (High) | bounty-hunter Fase 2 Tier 1 (PERKUAT); sc-audit Fase 2 (+invariant template); invariant-testing Catatan desain (+butir) |
| P-13 | Override ERC20 selektif | Eth #21 NaughtCoin (High) | sc-audit Fase 4 (+butir baru) |
| P-14 | Monitoring Forta sebagai permukaan pertahanan | Eth #22 DoubleEntryPoint (Critical) | sc-audit Fase 2 (+butir); bounty-hunter Fase 3 (+butir 11) |
| P-15 | Control flow berbasis custom error | Eth #23 GoodSamaritan (High) | sc-audit Fase 4 (+butir baru) |
| P-16 | Underflow panjang array 0.5 + delegatecall menimpa pointer library | Eth #25 AlienCodex (Critical); Eth #19 Preservation (Critical), #6 Delegation (Critical); DVD #8 Backdoor (Critical) | sc-audit Fase 4 Aritmetika (PERKUAT) + Upgradeability (PERKUAT) |
| P-17 | Randomness blockhash + constructor typo + underflow pra-0.8 | Eth #3 CoinFlip (Medium), #2 Fallout (High), #24 GatekeeperThree (High), #5 Token (High) | sc-audit Fase 4 Oracle + Access control + Aritmetika (PERKUAT) |
| P-18 | Jebakan harness Foundry (prank, view) | Eth #17/#18 Gatekeeper, #22 DoubleEntryPoint | invariant-testing Catatan desain (+butir) |

---

## P-01 — Oracle spot AMM tanpa TWAP

**Sumber:** DVD #11 Puppet (Critical — dump 1.000 DVT jatuhkan harga,
pinjam 100.000 DVT dengan deposit ~19,66 ETH); DVD #12 PuppetV2
(Critical — dump 10.000 DVT, deposit ~29,5 WETH, margin ~0,4 WETH);
Ethernaut #11 Dex (Critical — swap bolak-balik kuras satu sisi pool);
Ethernaut #12 DexTwo (Critical — token arbitrer + donasi 1 unit
sebagai penyebut harga).
**Root cause:** harga dibaca dari reserve/`balanceOf` AMM SAAT ITU
JUGA — tanpa TWAP/time-weighting — sehingga satu transaksi besar
menggeser harga secara permanen dalam satu blok. Varian tanpa oracle:
harga dihitung dari saldo pool itu sendiri (`getSwapPrice` dari
`balanceOf`) dan bergeser tiap swap.

**USULAN TEKS — sc-audit, Fase 4, butir "Oracle / manipulasi harga"
(PERKUAT butir yang sudah ada):**

```text
- **Oracle / manipulasi harga** — harga spot dari reserve AMM, tanpa
  TWAP, satu sumber atau oracle usang (tanpa cek `updatedAt`/round),
  pricing yang bisa dimanipulasi flash loan. **Tanyakan untuk setiap
  harga yang dibaca dari AMM: "TWAP/time-weighted, atau spot
  sesaat?"** Spot = dapat digerakkan permanen dalam satu blok oleh
  satu transaksi besar (DVD #11 Puppet: dump 1.000 DVT menjatuhkan
  harga → pinjam 100.000 DVT dengan deposit ~19,66 ETH; DVD #12
  PuppetV2: quote spot V2 → deposit ~29,5 WETH). Varian tanpa oracle:
  harga yang dihitung dari saldo pool itu sendiri (`getSwapPrice`
  dari `balanceOf`) bergeser tiap swap — swap bolak-balik
  menguntungkan penyerang tiap putaran (Ethernaut #11 Dex: kuras satu
  sisi pool; #12 DexTwo: token arbitrer sebagai `from` + donasi 1
  unit sebagai penyebut → harga dikendalikan penuh). Bila jumlah swap
  dibatasi saldo pool, periksa cap-nya (`amount = min(saldo, saldo
  pool from)`) — tanpa cap, `swapAmount` bisa melebihi saldo pool dan
  revert, tapi itu bukan mitigasi.
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 1, di bawah "Manipulasi
price oracle via flashloan" (PERKUAT):**

```text
- Manipulasi price oracle via flashloan — termasuk oracle yang membaca
  reserve/`balanceOf` AMM sesaat (tanpa TWAP) dan harga yang dihitung
  dari saldo pool itu sendiri (swap berulang menggeser rasio;
  Ethernaut Dex/DexTwo). Uji: bisakah satu transaksi besar menggeser
  harga secara permanen dalam satu blok? Bisakah token arbitrer
  dijadikan input harga?
```

---

## P-02 — Prediksi alamat CREATE

**Sumber:** DVD #13 SafeMiners (Critical — 2.000.042 DVT di alamat
deposit "kosong" dicuri TANPA private key; rantai CREATE Hardhat #1
nonce 1 → attack contract → sweeper nonce 66); Ethernaut #20 Recovery
(High — alamat token = CREATE nonce 1 dari Recovery, `destroy()`
publik).
**Root cause:** alamat CREATE (`keccak256(RLP([creator, nonce]))[12:]`)
dapat diprediksi; siapa pun yang men-deploy kontrak TEPAT di alamat
itu mengendalikan saldo di sana. Bukan bug kontrak — ini MEV/ordering
+ address prediction ("counterfactual address").

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Ekonomi / MEV":**

```text
- **Alamat counterfactual (CREATE/CREATE2)** — dana yang dikirim ke
  alamat yang belum ada kodenya belum tentu aman: alamat CREATE
  (`keccak256(RLP([creator, nonce]))`) dan CREATE2 dapat diprediksi
  dan dikendalikan siapa pun yang men-deploy duluan di sana. Periksa
  semua transfer ke alamat tanpa kode dan semua asumsi "alamat ini
  tidak bisa dikendalikan siapa pun". (DVD #13 SafeMiners: 2.000.042
  DVT di alamat deposit "kosong" dicuri tanpa private key — rantai
  CREATE Hardhat #1 nonce 1 → attack contract → sweeper nonce 66;
  Ethernaut #20 Recovery: alamat token = CREATE nonce 1 dari
  Recovery, `destroy()` publik.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 10 (setelah butir
9 "Tulis di `findings.md`"):**

```text
10. **Tanyakan tentang alamat tujuan.** Bila dana mengalir ke alamat
    yang belum ada kodenya, hitung apakah alamat itu CREATE/CREATE2
    yang dapat diprediksi — siapa yang bisa men-deploy kontrak di
    sana duluan? (DVD #13 SafeMiners; Ethernaut #20 Recovery.)
```

---

## P-03 — Tabrakan storage proxy

**Sumber:** Ethernaut #13 PuzzleWallet (Critical — pengambilalihan
admin proxy + pengurasan saldo).
**Root cause:** tiga cacat bergabung — (1) proxy (`pendingAdmin`
slot 0, `admin` slot 1) vs implementasi (`owner` slot 0, `maxBalance`
slot 1): `proposeNewAdmin(player)` menulis slot 0 proxy = `owner`;
`setMaxBalance` menulis slot 1 = `admin`. (2) Guard "deposit hanya
sekali" hanya hidup per-frame `multicall` — `multicall` bersarang
mereset guard sehingga `deposit()` dieksekusi 2× dengan `msg.value`
yang sama (delegatecall mempertahankan `msg.value`).

**USULAN TEKS — sc-audit, Fase 4, butir "Upgradeability /
delegatecall" (PERKUAT):**

```text
- **Upgradeability / delegatecall** — tabrakan layout storage,
  proxy belum diinisialisasi, initializer tanpa guard, `selfdestruct` /
  `delegatecall` di implementasi, bentrok selector. **Periksa tabrakan
  slot proxy vs implementasi satu per satu:** proxy (`pendingAdmin`
  slot 0, `admin` slot 1) vs implementasi (`owner` slot 0,
  `maxBalance` slot 1) — fungsi proxy yang menulis slot bisa menulis
  variabel implementasi dan sebaliknya (Ethernaut #13 PuzzleWallet:
  `proposeNewAdmin` → jadi owner; `setMaxBalance` → jadi admin).
  Periksa juga guard yang hanya hidup per-frame: `multicall`
  bersarang mereset guard "deposit hanya sekali" sehingga `msg.value`
  yang sama dipakai 2× (deposit ganda).
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 2, butir "Proxy
upgradeable" (PERKUAT):**

```text
- **Proxy upgradeable** — storage collision, otorisasi UUPS, konflik facet diamond. Tambah: tabrakan slot proxy-vs-implementasi (cek layout keduanya berdampingan, bukan masing-masing) dan guard per-frame pada multicall bersarang (Ethernaut #13 PuzzleWallet).
```

---

## P-04 — Init UUPS tak terlindungi + EIP-6780

**Sumber:** Ethernaut #14 Motorbike (Critical — penghancuran
implementation kontrak upgradeable).
**Root cause:** `Engine.initialize()` hanya pernah dipanggil lewat
`delegatecall` di konteks proxy — storage Engine sendiri tidak pernah
terinisialisasi, jadi siapa pun bisa memanggil `initialize()` langsung
di alamat Engine, menjadi `upgrader`, lalu `upgradeToAndCall` ke
implementasi jahat yang `selfdestruct`. **EIP-6780 (Cancun):**
`SELFDESTRUCT` hanya menghapus kode bila kontrak dibuat di transaksi
yang SAMA — instance yang dibuat di `setUp()` lalu dihancurkan di
`testSolve()` TIDAK hilang; temuan interaksi EVM modern pertama di
seluruh benchmark.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Upgradeability
/ delegatecall":**

```text
- **Implementation UUPS yang belum terinisialisasi** — `initialize()`
  yang hanya dipanggil lewat `delegatecall` di konteks proxy berarti
  storage implementation sendiri TIDAK pernah terinisialisasi: siapa
  pun bisa memanggil `initialize()` langsung di alamat implementation
  dan menjadi `upgrader`, lalu `upgradeToAndCall` ke implementasi
  jahat yang `selfdestruct`. (Ethernaut #14 Motorbike.) **EIP-6780
  (Cancun):** `SELFDESTRUCT` hanya menghapus kode bila kontrak dibuat
  di transaksi yang SAMA — exploit penghancuran harus dirancang satu
  transaksi; selalu periksa `evm_version` target saat menulis PoC.
```

**USULAN TEKS — bounty-hunter, Fase 4, bagian "Syarat PoC",
butir baru setelah daftar fork:**

```text
- **Periksa `evm_version` target sebelum menulis PoC penghancuran.**
  Sejak Cancun (EIP-6780), `SELFDESTRUCT` hanya menghapus kode bila
  kontrak dibuat di transaksi yang sama. Instance yang dibuat di
  `setUp()` lalu dihancurkan di `testSolve()` TIDAK akan hilang —
  buat instance baru di dalam fungsi test yang sama. (Ethernaut #14
  Motorbike.)
```

---

## P-05 — Gerbang gas + extcodesize + serangan dari constructor

**Sumber:** Ethernaut #17 GatekeeperOne (High — gerbang gas
`gasleft() % 8191`, brute force 8.191 nilai; kunci masking
`0x000000010000BEEF`); Ethernaut #18 GatekeeperTwo (High —
`extcodesize == 0` hanya selama konstruksi; kunci XOR
`keccak256(msg.sender)`).
**Root cause:** (a) gas adalah parameter yang dikendalikan pemanggil
— gerbang `gasleft() % N == 0` bisa di-brute-force lewat low-level
`call` dengan 8.191 nilai gas berurutan. (b) `extcodesize` sebuah
kontrak adalah 0 hanya selama konstruksinya — serangan harus
dieksekusi dari constructor.

**USULAN TEKS — sc-audit, Fase 4, butir "Access control" (PERKUAT):**

```text
- **Access control** — modifier hilang/salah, `initialize` tanpa guard,
  auth `tx.origin`, fungsi owner-only yang dibiarkan external, jalur
  pemberian role, otorisasi upgrade. **Tambahan dari benchmark:**
  (a) gerbang berbasis gas (`gasleft() % N == 0`) — gas adalah
  parameter yang dikendalikan pemanggil dan bisa di-brute-force
  (Ethernaut #17 GatekeeperOne: 8.191 nilai gas berurutan);
  (b) `extcodesize == 0` sebagai bukti "bukan kontrak" — salah,
  karena selama konstruksi kontrak belum punya kode, jadi serangan
  harus dieksekusi dari constructor (Ethernaut #18 GatekeeperTwo);
  (c) kunci yang dimasking bit (`uint32`/`uint16` vs `uint64`, XOR
  dengan `keccak256`) — hitung kunci yang benar dari
  `msg.sender`/`tx.origin`, jangan tebak.
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 1, di bawah "Access
control" (PERKUAT):**

```text
- Gerbang berbasis gas dan `extcodesize` — keduanya asumsi yang salah: gas bisa di-brute-force pemanggil; `extcodesize == 0` benar selama konstruksi. (Ethernaut #17/#18.)
```

---

## P-06 — Storage packing + private terbaca

**Sumber:** Ethernaut #16 Privacy (High — `data[2]` di slot 5; tiga
variabel kecil di-pack dalam satu slot); Ethernaut #8 Vault (High —
password di slot 1); Ethernaut #25 AlienCodex (Critical — packing
lintas inheritance: `contact` bool terpacking di byte 20 slot 0,
`codex.length` di slot 1 — tebakan awal "slot 2" salah total,
dibuktikan via probe `vm.load` per slot).
**Root cause:** `private` hanya menyembunyikan dari compiler, bukan
dari pembaca chain. Layout storage harus dihitung dengan benar
termasuk packing — dan packing lintas inheritance menyesatkan:
variabel `bool` dari kontrak turunan bisa terpacking ke sisa slot 0
milik base contract. Keccak-256 ≠ SHA3-256 (`hashlib.sha3_256`
Python adalah NIST SHA3 — pakai `pycryptodome` atau Foundry).

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Aritmetika /
presisi":**

```text
- **Storage layout — ukur, jangan tebak.** `private` hanya
  menyembunyikan dari compiler, bukan dari pembaca chain. Hitung slot
  dengan benar termasuk packing: tiga variabel kecil bisa berbagi satu
  slot, dan variabel `bool` dari kontrak turunan bisa terpacking ke
  sisa slot 0 milik base contract (Ethernaut #25 AlienCodex:
  `contact` di byte 20 slot 0, `codex.length` di slot 1 — tebakan
  awal "slot 2" salah total). Verifikasi slot dengan `vm.load` /
  `cast storage` SEBELUM menulis PoC yang bergantung pada slot.
  Keccak-256 ≠ SHA3-256: `hashlib.sha3_256` Python adalah NIST SHA3
  (padding berbeda) — pakai `pycryptodome` (`Crypto.Hash.keccak`)
  atau Foundry untuk menghitung slot array (`keccak256(slot) + i`).
```

**USULAN TEKS — bounty-hunter, Fase 1, langkah baru 6 (setelah
langkah 5 "Jalankan scan otomatis"):**

```text
- 6. Petakan layout storage variabel sensitif (slot + packing) untuk
  variabel `private` — rahasia on-chain adalah publik (Ethernaut #8
  Vault, #16 Privacy, #25 AlienCodex).
```

---

## P-07 — Push-payment DoS

**Sumber:** Ethernaut #9 King (High — king yang `receive()`-nya
revert tak bisa digulingkan, fungsi inti lumpuh permanen); Ethernaut
#24 GatekeeperThree (High — gerbang ketiga: `send` 0,001 ether ke
owner GAGAL karena owner adalah kontrak tanpa `receive()`/`fallback`).
**Root cause:** bila kontrak mengirim ETH/token ke alamat yang dipilih
pihak lain dan transaksi gagal bila penerima menolak, fungsi inti
lumpuh permanen — penerima yang menolak menjadi king selamanya.

**USULAN TEKS — sc-audit, Fase 4, butir "Asumsi pemanggilan
eksternal" (PERKUAT):**

```text
- **Asumsi pemanggilan eksternal** — return value tak dicek, ERC20
  non-standar (tanpa return value, **fee-on-transfer**, rebasing),
  DoS lewat revert-dalam-loop, griefing gas. **Push-payment DoS:**
  bila kontrak mengirim ETH/token ke alamat yang dipilih pihak lain
  (king baru, owner, partner) dan transaksi gagal bila penerima
  menolak (`receive()` revert / tanpa `receive`), fungsi inti lumpuh
  permanen — penerima yang menolak menjadi king selamanya (Ethernaut
  #9 King; #24 GatekeeperThree: `send` ke owner kontrak tanpa
  `receive()` sengaja digagalkan). Pakai pola pull-payment; jangan
  pernah mengasumsikan penerima bisa menerima.
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 3, setelah "DoS via
block gas limit dalam loop" (PERKUAT):**

```text
- Push-payment DoS — penerima yang menolak pembayaran melumpuhkan fungsi inti (Ethernaut #9 King). Cari pola `transfer`/`send`/`call` ke alamat pilihan pihak lain di tengah alur.
```

---

## P-08 — Gas griefing + aturan 63/64 + semantik assert 0.8

**Sumber:** Ethernaut #26 Denial (Medium — DoS pada penarikan: dana
terkunci, bukan dicuri).
**Root cause:** (1) Aturan EIP-150 (63/64): low-level `call` hanya
meneruskan 63/64 gas; pemanggil menyimpan ~1/64. Dari gas 1.000.000,
pemanggil menyimpan ~15,6k — tidak cukup untuk `transfer` (11.600) +
2 SSTORE (~20k masing-masing) → pemanggil OOG di tengah jalan →
revert. (2) `assert(false)` di Solidity 0.8 adalah REVERT dengan
Panic(0x01) yang mengembalikan gas tak terpakai — BUKAN INVALID yang
menghabiskan gas. Exploit gas-griefing harus benar-benar membakar gas
(loop tak berujung + SSTORE).

**USULAN TEKS — sc-audit, Fase 4, butir "Asumsi pemanggilan
eksternal" (PERKUAT — tambah paragraf setelah butir P-07):**

```text
- **Gas griefing + aturan EIP-150 (63/64).** Low-level `call` hanya
  meneruskan 63/64 gas; pemanggil menyimpan ~1/64. Bila fallback
  penerima membakar seluruh gas yang diteruskan, pemanggil kehabisan
  gas di tengah jalan (transfer + SSTORE setelah call tidak sempat)
  → revert. Hitung angkanya: dari gas 1.000.000, pemanggil menyimpan
  ~15,6k — tidak cukup untuk `transfer` (11.600) + 2 SSTORE.
  **Semantik `assert` berubah di Solidity 0.8:** `assert(false)`
  adalah REVERT dengan Panic(0x01) yang mengembalikan gas tak
  terpakai — BUKAN INVALID yang menghabiskan gas. Exploit gas-griefing
  harus benar-benar membakar gas (loop tak berujung + SSTORE).
  (Ethernaut #26 Denial.)
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Jangan assert health factor..."):**

```text
- **Invariant yang bergantung pada gas tidak bisa difuzz seperti
  biasa.** `assert` Solidity 0.8 mengembalikan gas (bukan INVALID),
  dan aturan 63/64 membatasi gas yang diteruskan ke `call`. Bila
  properti melibatkan kehabisan gas, buktikan dengan PoC
  deterministik + hitungan gas, bukan dengan fuzz. (Ethernaut #26
  Denial.)
```

---

## P-09 — Unchecked return value + baca state 2×

**Sumber:** Ethernaut #30 Stake (Critical — insolvensi akuntansi:
`totalStaked` tercatat melebihi dana yang benar-benar ada); Ethernaut
#27 Shop (High — membeli barang seharga 0); Ethernaut #15 Elevator
(Medium — `isLastFloor` dipanggil 2×, dijawab berbeda tiap panggilan).
**Root cause:** (a) `transferFrom` yang gagal diam-diam (`false`)
sementara akuntansi tetap jalan = stake hantu — cabang `else` tanpa
cek vs cabang `if` dengan cek adalah celah klasik; state berubah
SEBELUM `send` yang gagal (`Unstake` meng-nolkan saldo walau `send`
gagal). (b) Fungsi `view` bisa membaca state yang berubah di tengah
eksekusi: `buy()` memanggil `price()` 2× — pertama `isSold == false`
→ 100, kedua → 0. Sepupunya: fungsi eksternal yang menjawab berbeda
tiap panggilan.

**USULAN TEKS — sc-audit, Fase 4, butir "Asumsi pemanggilan
eksternal" (PERKUAT — tambah paragraf):**

```text
  Return value yang tidak dicek adalah kelas tersendiri: `transferFrom`
  yang gagal diam-diam (`false`) sementara akuntansi tetap jalan =
  stake hantu dan insolvensi (`totalStaked` tercatat melebihi dana
  yang benar-benar ada — Ethernaut #30 Stake; cabang `else` tanpa
  cek vs cabang `if` dengan cek adalah celah klasik). Periksa juga
  state yang berubah SEBELUM `send` yang gagal — `Unstake` yang
  meng-nolkan saldo walau `send` gagal.
```

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Asumsi
pemanggilan eksternal":**

```text
- **Baca state yang sama 2× dalam satu transaksi.** Fungsi `view`
  bisa membaca state yang berubah di tengah eksekusi — harga yang
  dibaca dua kali bisa berbeda (Ethernaut #27 Shop: `price()` dibaca
  di kondisi `if` lalu untuk menetapkan harga; `isSold` berubah di
  antaranya → 100 lalu 0). Sepupunya: fungsi eksternal yang menjawab
  berbeda tiap panggilan (Ethernaut #15 Elevator: `isLastFloor`
  dipanggil 2×, dijawab `false` lalu `true`). Audit harus curiga pada
  pemanggilan berulang ke fungsi yang sama dalam satu transaksi —
  baca sekali, simpan, pakai hasilnya.
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru
(setelah "Urutan gagal yang ter-shrink..."):**

```text
- [ ] Bila protokol membaca state yang sama 2× dalam satu transaksi
  (harga, saldo, flag), invariant ditulis atas SATU pembacaan —
  pembacaan kedua bisa berbeda bila state berubah di antaranya
  (Ethernaut #27 Shop, #15 Elevator).
```

---

## P-10 — Hardcoded offset calldata

**Sumber:** Ethernaut #29 Switch (High — bypass modifier otorisasi).
**Root cause:** modifier `onlyOff` membaca selector dari posisi
calldata 68 secara hardcode, dengan asumsi offset `_data` = 0x20.
Dengan offset `_data` = 0x60, decoder ABI membaca length di byte 100
dan `_data` di byte 132 — sementara modifier tetap membaca byte 68.
Payload 136 byte menaruh `offSelector` di byte 68 dan `onSelector` di
byte 132.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Signature /
replay":**

```text
- **Parsing calldata manual dengan offset hardcode.** Bila kontrak
  membaca selector/argumen dari posisi calldata tetap (mis.
  `calldatacopy(selector, 68, 4)` dengan asumsi offset `_data` =
  0x20), pemanggil bisa menggeser offset (0x60) sehingga modifier
  membaca byte yang salah sementara decoder ABI membaca yang benar —
  bypass modifier otorisasi. Uji parsing manual dengan offset
  berbeda. (Ethernaut #29 Switch.)
```

---

## P-11 — Bytecode minimal / baca opcode

**Sumber:** Ethernaut #28 MagicNum (Medium — bukan kerentanan dana;
teka-teki bytecode EVM).
**Root cause:** tidak ada kerentanan logika — solver 10 byte runtime
(`602a60005260206000f3`) + 12 byte creation mengembalikan 42.
Relevansinya untuk audit: kontrak 10 byte pun bisa punya logika;
jangan anggap kontrak kecil/tanpa source = tidak berbuat apa-apa.
**CATATAN BATASAN:** pola ini TIDAK mengubah aturan sc-audit bahwa
audit bytecode-only di luar scope tanpa source — ini hanya kemampuan
recon (membaca opcode mentah), bukan perluasan scope audit.

**USULAN TEKS — bounty-hunter, Fase 1.5, catatan baru (setelah
bagian scanning otomatis):**

```text
- **Kontrak tanpa source / bytecode rakitan tangan.** Bila target
  hanya bytecode (tanpa source terverifikasi), baca opcode mentah:
  kontrak 10 byte pun bisa punya logika (Ethernaut #28 MagicNum:
  runtime `602a60005260206000f3` mengembalikan 42). Jangan anggap
  kontrak kecil = tidak ada logika.
```

---

## P-12 — Flash-loan governance + snapshot manipulation

**Sumber:** DVD #6 Selfie (Critical — pinjam 1.500.000/2.000.000
token (75%), snapshot DI DALAM callback → mayoritas voting → antre
`drainAllFunds` → warp 2 hari → eksekusi; chaining 3 langkah);
DVD #5 The Rewarder (High — `deposit()` MINT accToken dulu, BARU
`distributeRewards()` mencatat snapshot ronde baru; flash loan
1.000.000 DVT tepat sebelum snapshot → ~99,96 dari 100 reward).
**Root cause:** (a) voting power dari snapshot TERAKHIR, dan siapa
pun bisa memicu snapshot baru (`snapshot()` publik tanpa guard) —
modal sementara = mayoritas sesaat. (b) Snapshot dicatat SETELAH
perubahan saldo, sehingga snapshot sudah mencakup saldo penyerang.

**USULAN TEKS — bounty-hunter, Fase 2, Tier 1, di bawah "Access
control" (PERKUAT — tambah sub-butir governance):**

```text
- Governance bypass — termasuk takeover via flash-loan voting power: snapshot yang bisa dipicu siapa pun + pinjaman mayoritas sementara = mayoritas sesaat (DVD #6 Selfie: pinjam 75% supply, snapshot di callback, antre `drainAllFunds`, warp 2 hari, eksekusi).
```

**USULAN TEKS — sc-audit, Fase 2, bagian "Invariant protokol",
template invariant baru:**

```text
- Voting/governance: "voting power tidak bisa dipompa dalam satu
  transaksi" — voting power harus dari snapshot LAMA (bukan terakhir),
  snapshot hanya oleh kontrak tepercaya / pada waktu tetap, atau
  quorum yang tidak bisa dipompa dalam satu transaksi. (DVD #6
  Selfie.)
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Jebakan ghost saat early return"):**

```text
- **Invariant snapshot: snapshot DULU, baru mint.** Bila protokol
  mencatat snapshot ronde baru SETELAH mint, snapshot sudah mencakup
  saldo penyerang — flash loan 1.000.000 DVT tepat sebelum snapshot
  memberi ~99,96% reward ronde itu (DVD #5 The Rewarder). Tulis
  invariant "saldo snapshot ronde N == saldo pada akhir ronde N−1"
  dan uji dengan handler yang memompa saldo tepat sebelum snapshot
  (beri handler dana tak terbatas ala flash loan — disiplin dari
  studi ItyFuzz fase D).
```

---

## P-13 — Override ERC20 selektif

**Sumber:** Ethernaut #21 NaughtCoin (High — timelock 10 tahun
dilewati via `approve` + `transferFrom`).
**Root cause:** `transfer()` di-override dengan cek timelock — tapi
`transferFrom()` TIDAK di-override, jadi jalur itu memakai
implementasi ERC20 standar tanpa cek timelock. Penguncian diterapkan
di satu fungsi tapi jalur setara dibiarkan terbuka.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Aritmetika /
presisi":**

```text
- **Override yang tidak lengkap.** Bila kontrak meng-override satu
  fungsi dengan guard (mis. `transfer()` dengan timelock) tapi
  membiarkan jalur setara tanpa guard (`transferFrom()` tidak
  di-override → implementasi standar tanpa cek), guard bisa dilewati
  lewat jalur yang tidak di-override. Periksa SEMUA jalur setara
  (`transfer`, `transferFrom`, `transferFrom` via `permit`,
  `delegateTransfer`) untuk setiap guard. (Ethernaut #21 NaughtCoin:
  timelock 10 tahun dilewati via `approve` + `transferFrom`.)
```

---

## P-14 — Monitoring Forta sebagai permukaan pertahanan

**Sumber:** Ethernaut #22 DoubleEntryPoint (Critical — pengurasan
penuh vault lewat jalur delegasi tersembunyi).
**Root cause:** `sweepToken(LGT)` memanggil `LGT.transfer(...)` →
`LGT` mendelegasikan ke `DET.delegateTransfer(to, value,
origSender=vault)` → `DET` vault ikut terkirim. Satu-satunya
pertahanan: detection bot Forta — `fortaNotify` memanggil
`bot.handleTransaction(user, msgData)`; bila bot memanggil
`forta.raiseAlert(user)`, `delegateTransfer` revert dan sweep gagal.
Bot harus raise alert bila `origSender == vault`.

**USULAN TEKS — sc-audit, Fase 2, bagian "Aktor & trust boundary",
butir baru:**

```text
- **Sistem monitoring sebagai permukaan pertahanan.** Bila protokol
  mengandalkan detection bot / monitoring on-chain (mis. Forta),
  bot itu sendiri adalah bagian dari model ancaman: uji apakah bot
  bisa di-bypass (kondisi alert tidak mencakup jalur serangan),
  dimatikan, atau diakali. Serangan bisa lewat jalur delegasi
  tersembunyi yang tidak dilihat bot. (Ethernaut #22
  DoubleEntryPoint: `sweepToken(LGT)` mendelegasikan transfer DET
  vault; hanya bot yang raise alert bila `origSender == vault` yang
  menghentikan sweep.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 11 (setelah
butir 10 dari P-02):**

```text
11. **Lacak jalur delegasi tersembunyi.** Bila kontrak A memanggil
    kontrak B yang mendelegasikan ke kontrak C, nilai bisa mengalir
    lewat jalur yang tidak terlihat di kontrak A. (Ethernaut #22
    DoubleEntryPoint.)
```

---

## P-15 — Control flow berbasis custom error

**Sumber:** Ethernaut #23 GoodSamaritan (High — pengurasan penuh
wallet lewat penyalahgunaan error handling).
**Root cause:** `donate10` memanggil `notify(amount)` pada penerima.
Bila `notify` revert dengan custom error persis `NotEnoughBalance()`,
`catch` mengira wallet kehabisan saldo dan memanggil
`transferRemainder` — seluruh saldo mengalir ke penyerang. Revert
yang seharusnya sinyal kegagalan dipakai sebagai pemicu jalur darurat.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Signature /
replay":**

```text
- **Control flow berbasis tipe error / try-catch.** Revert yang
  seharusnya sinyal kegagalan bisa dipakai sebagai pemicu jalur
  darurat: bila `catch` membandingkan tipe error persis (mis.
  `NotEnoughBalance()`) lalu memanggil fungsi yang menguras saldo,
  penyerang cukup me-revert dengan error yang sama persis untuk
  memicu jalur itu. Periksa setiap `catch` yang memanggil fungsi
  berdana — apa yang terjadi bila error itu dibuat-buat oleh
  penerima? (Ethernaut #23 GoodSamaritan.)
```

---

## P-16 — Underflow panjang array 0.5 + delegatecall menimpa pointer library

**Sumber:** Ethernaut #25 AlienCodex (Critical — underflow panjang
array); Ethernaut #19 Preservation (Critical — delegatecall library
menimpa pointer library); Ethernaut #6 Delegation (Critical —
delegatecall tak terbatas ke `pwn()`); DVD #8 Backdoor (Critical —
delegatecall `to`/`data` arbitrer saat Gnosis Safe setup).
**Root cause:** (a) `retract()` mengurangi panjang array tanpa
checked arithmetic (Solidity 0.5): pada array kosong, `length--`
UNDERFLOW → length = 2^256 − 1, lalu `revise(i, ...)` bisa menulis ke
slot mana pun (slot 0 = `_owner`, indeks `2^256 − keccak256(1)`).
(b) Fungsi library yang menulis slot 0 menimpa ALAMAT LIBRARY itu
sendiri bila dipanggil via `delegatecall` (slot 0 Preservation =
`timeZone1Library`): `setFirstTime(alamatPenyerang)` → panggilan
berikutnya mendelegatecall kontrak penyerang → `owner = msg.sender`.
(c) Varian setup-time: `GnosisSafe.setup()` menjalankan DELEGATECALL
ke `to`/`data` arbitrer — registry memeriksa factory, master copy,
selector setup, threshold, owner, tapi TIDAK PERNAH memeriksa
`to`/`data`.

**USULAN TEKS — sc-audit, Fase 4, butir "Aritmetika / presisi"
(PERKUAT — tambah sub-butir):**

```text
- **Underflow panjang array dinamis (Solidity <0.8).** `length--`
  pada array kosong underflow ke 2^256−1 → `revise(i, ...)` bisa
  menulis ke slot mana pun, termasuk slot 0 (`_owner`). (Ethernaut
  #25 AlienCodex.)
```

**USULAN TEKS — sc-audit, Fase 4, butir "Upgradeability /
delegatecall" (PERKUAT — tambah paragraf setelah butir P-03):**

```text
  **Delegatecall yang menimpa pointer-nya sendiri.** Fungsi library
  yang menulis slot 0 menimpa ALAMAT LIBRARY itu sendiri bila
  dipanggil via `delegatecall` (slot 0 Preservation =
  `timeZone1Library`): `setFirstTime(alamatPenyerang)` → panggilan
  berikutnya mendelegatecall kontrak penyerang → `owner =
  msg.sender`. (Ethernaut #19 Preservation.) Varian setup-time:
  `delegatecall` ke `to`/`data` arbitrer saat setup (DVD #8
  Backdoor: registry memeriksa factory/master copy/selector/threshold/
  owner tapi TIDAK PERNAH memeriksa `to`/`data`).
```

---

## P-17 — Randomness blockhash + constructor typo + underflow pra-0.8

**Sumber:** Ethernaut #3 CoinFlip (Medium — randomness dari
`blockhash(block.number-1)` dapat diprediksi); Ethernaut #2 Fallout
(High — constructor typo `Fal1out` (angka 1), fungsi publik biasa di
0.6); Ethernaut #24 GatekeeperThree (High — `construct0r()` typo);
Ethernaut #5 Token (High — integer underflow 0.6: transfer 21 dari
saldo 20 → 2^256−1).
**Root cause:** tiga pola klasik yang masing-masing satu baris: (a)
randomness dari state chain yang dapat diprediksi/dipengaruhi
penambang; (b) constructor yang salah eja adalah fungsi publik biasa
yang bisa dipanggil siapa pun; (c) aritmetika pra-0.8 tanpa checked
arithmetic bawaan.

**USULAN TEKS — sc-audit, Fase 4, tiga penambahan kecil:**

```text
# Butir "Oracle / manipulasi harga" (PERKUAT — tambah kalimat):
  Randomness dari `blockhash`/`block.timestamp` dapat diprediksi —
  jangan pakai sebagai sumber acak. (Ethernaut #3 CoinFlip.)

# Butir "Access control" (PERKUAT — tambah kalimat):
  Constructor yang salah eja (`Fal1out`, `construct0r`) adalah fungsi
  publik biasa yang bisa dipanggil siapa pun — periksa nama
  constructor vs nama kontrak. (Ethernaut #2 Fallout, #24
  GatekeeperThree.)

# Butir "Aritmetika / presisi" (PERKUAT — tambah kalimat):
  Underflow pra-0.8 (tanpa checked arithmetic bawaan): transfer
  melebihi saldo → saldo 2^256−1. (Ethernaut #5 Token.)
```

---

## P-18 — Jebakan harness Foundry (prank, view)

**Sumber:** Ethernaut #17/#18 Gatekeeper One/Two (prank 1 argumen
tidak mengubah `tx.origin`); Ethernaut #22 DoubleEntryPoint (prank
habis dimakan panggilan `view`).
**Root cause:** ini BUKAN pola kerentanan — ini jebakan alat yang
memakan waktu debug di benchmark (Gatekeeper: ~8 menit; DEP: 1
kegagalan harness). Nilainya: PoC/harness yang salah bisa membuat
temuan benar terlihat gagal. Masuk ke invariant-testing karena skill
itu yang memuat disiplin harness Foundry.

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Jebakan ghost saat early return"):**

```text
- **Jebakan `vm.prank` di Foundry.** `prank(addr)` 1 argumen hanya
  mengubah `msg.sender`, bukan `tx.origin` — untuk keduanya pakai
  `startPrank(addr, addr)` / `prank(addr, addr)` (Ethernaut #17/#18
  Gatekeeper). Dan prank hanya berlaku SATU panggilan berikutnya —
  termasuk panggilan `view` (Ethernaut #22 DoubleEntryPoint: prank
  habis dimakan `instance.forta()`). Baca semua alamat yang
  dibutuhkan dulu, baru prank.
```

---

## Yang TIDAK diusulkan (sudah tercakup memadai)

Pola-pola berikut sudah ada di skill dengan rumusan yang cukup — TIDAK
perlu blok baru, hanya dicatat sebagai konfirmasi dari benchmark:

- **Reentrancy klasik** (Ethernaut #10 Re-entrancy, Critical) —
  sudah di bounty-hunter Tier 1 + sc-audit Fase 4 ("Reentrancy —
  satu fungsi, antar-fungsi, antar-kontrak, read-only reentrancy").
- **Access control dasar** (missing `onlyOwner`, initializer tanpa
  guard) — sudah di bounty-hunter Tier 1 + sc-audit Fase 4.
- **`tx.origin` sebagai auth** (Ethernaut #4 Telephone, High) —
  sudah di sc-audit Fase 4 Access control ("auth `tx.origin`").
- **Delegatecall tak terbatas ke selector arbitrer** (Ethernaut #6
  Delegation, Critical) — sudah di sc-audit Fase 4 Upgradeability
  ("`delegatecall` di implementasi") + bounty-hunter Tier 1
  ("Delegatecall terkontrol").
- **Inflasi share / first-depositor** — sudah di bounty-hunter Tier 1
  + sc-audit Fase 4 Aritmetika ("inflasi share deposan pertama
  ERC-4626").
- **Rounding/presisi** — sudah di bounty-hunter Fase 2 ranking #2 +
  sc-audit Fase 4 Aritmetika.
- **`private` storage terbaca (varian sederhana)** (Ethernaut #8
  Vault, High) — tercakup oleh P-06 (varian packing yang lebih sulit);
  tidak perlu butir terpisah.
- **Constructor typo sebagai pola tersendiri** — tercakup oleh P-17
  (satu kalimat di Access control), tidak perlu butir baru.

## Catatan verifikasi (untuk main chat)

- Dokumen ini PROPOSAL — tidak ada file skill yang diubah. Periksa
  sebelum menerapkan: (1) setiap sumber pola ada di baseline yang
  dirujuk (DVD 13/13 + Ethernaut 30/30, semua lolos `forge test`
  segar); (2) setiap blok teks dalam Bahasa Indonesia, tanpa referensi
  ke tool AI lain, tanpa alias model, tanpa API key, tanpa perintah
  install; (3) penempatan sesuai struktur skill yang ada (nomor fase
  dan nama butir dicek dari file skill saat ini:
  bounty-hunter 572 baris, sc-audit 349 baris, invariant-testing 178
  baris — 16 Nov 2026).
- Setelah diterapkan, main chat memverifikasi tiap skill yang diubah
  (hitung baris, frontmatter, grep pola terlarang) sebelum menyatakan
  skill diperbarui — sama seperti adopsi skill baru.
- Pola yang TIDAK masuk proposal ini karena di luar scope benchmark:
  pola dari korpus C4/Cantina (`vulnerability-patterns/c4-cantina-
  2026-11-16.md` — 7 pola terbukti menang) dan metodologi fase B
  (`methodologies/` — Halmos/Echidna/Medusa/Aderyn/trailofbits-skills/
  BSC). Keduanya layak jadi proposal integrasi terpisah (fase K).

## Langkah berikut

1. Main chat: terapkan blok P-01..P-18 ke tiga skill (atau tolak
   sebagian dengan alasan) → verifikasi → catat di tracker + inventory.
2. Proposal integrasi terpisah (fase K): 7 pola korpus C4/Cantina +
   disiplin metodologi fase B (kasus batas manual ala Halmos, korpus +
   minimisasi ala Echidna/Medusa, uji tautologi/vakum ala
   trailofbits-skills).
3. Benchmark berikut: Capture The Ether (sesuai rencana misi).
