# Proposal Integrasi Pola Korpus C4/Cantina + Metodologi Fase B ke Skill — Pass 2 fase K

**Tanggal:** 16 November 2026 (misi Skill Evolution, Pass 2 fase K)
**Status:** PROPOSAL SAJA — file skill TIDAK diubah. Main chat yang
menerapkan + memverifikasi (hitung baris, frontmatter, grep pola
terlarang) sebelum menyatakan skill diperbarui. JANGAN klaim skill
sudah diperbarui berdasarkan dokumen ini.
**Sumber:** (1) korpus laporan kontes audit publik —
`vulnerability-patterns/c4-cantina-2026-11-16.md` (442 baris): 3 laporan
final dibaca penuh — Code4rena Monetrix 2026-04 (M-01 Medium, satu-satunya
temuan; 39 warden duplikat), Cantina/Spearbit Mercury 15 Mei 2026
(5 Critical / 5 High / 2 Medium dari 28 isu), Cantina EigenLayer
5 Apr 2024 (1 High dari 71 isu). Semua pola di bawah ini MENANG di
kontes nyata, dengan PoC dan angka dampak. (2) Metodologi fase B —
`methodologies/halmos-symbolic-testing.md` (155 baris),
`methodologies/echidna-medusa-property-fuzzing.md` (204 baris),
`methodologies/trailofbits-skills-rewrite.md` (232 baris): tulis ulang
kata sendiri, tanpa adopsi kode/install (pengecualian lisensi Mas
21:13 WIB). (3) Proposal fase J —
`research/skill-integration-2026-11-16.md` (799 baris, P-01..P-18,
sudah diterapkan + diverifikasi main chat ke ketiga skill) — dicek
lebih dulu agar tidak ada duplikasi; tumpang tindih ditulis PERKUAT
atau dilewati dengan alasan.
**Total pola baru di sini:** 7 pola korpus (C-01..C-07) + 1 framing
severity (F-01) + 4 disiplin metodologi (M-01..M-04).

## Prinsip penempatan

1. **bounty-hunter** = pola berburu + PoC. Masuk ke Fase 2 (ranking
   prioritas + Tier 1/2/3), Fase 3 (deep dive), atau Fase 5 (laporan).
   Pola yang mengubah CARA berburu masuk sini.
2. **sc-audit** = pola audit. Masuk ke Fase 2 (model ancaman),
   Fase 3 (attack surface), atau Fase 4 (checklist deep review).
   Pola yang mengubah APA YANG DIPERIKSA masuk sini.
3. **invariant-testing** = pola yang bisa difuzz/dibuktikan mesin.
   Masuk ke "Catatan desain" atau "Checklist". Pola yang mengubah
   INVARIANT APA yang ditulis masuk sini.
4. Bila skill sudah mencantumkan pola yang sama secara umum, proposal
   TIDAK menulis ulang — hanya MEMPERKUAT dengan varian + contoh
   konkret dari korpus (diberi label "PERKUAT").
5. Setiap blok teks diusulkan persis seperti tertulis (Bahasa
   Indonesia). Main chat boleh mengedit redaksi saat menerapkan, tapi
   substansi (pola + contoh + sumber) harus tetap.

## Matriks penempatan (ringkas)

| ID | Pola | Sumber (severity) | Skill → lokasi |
|---|---|---|---|
| C-01 | Akuntansi satu sisi: aset dikredit, kewajiban diabaikan | Monetrix M-01 (Medium); Mercury 3.1.5 (Critical), 3.3.1/3.3.2 (Medium) | sc-audit Fase 4 (+butir baru); bounty-hunter Fase 2 Tier 2 (PERKUAT); invariant-testing Catatan desain (+butir) |
| C-02 | Double-counting / double-spend saat inisialisasi | Mercury 3.1.4 (Critical), 3.1.5 (Critical) | sc-audit Fase 4 (+butir baru); bounty-hunter Fase 3 (+butir 12); invariant-testing Checklist (+butir) |
| C-03 | Dana bersama tanpa pemisahan kepemilikan (contagion) | Mercury 3.1.4 (Critical) | sc-audit Fase 4 (+butir baru); bounty-hunter Fase 2 Tier 2 (+butir baru); invariant-testing Catatan desain (+butir) |
| C-04 | Boundary off-by-one + urutan eksekusi yang diasumsikan | EigenLayer 3.1.1 (High); Mercury 3.1.3 (Critical) | sc-audit Fase 4 (+butir baru); bounty-hunter Fase 3 (+butir 13) |
| C-05 | Matematika ill-conditioned: benar secara aljabar, salah secara numerik | Mercury 3.1.1 (Critical); 3.2.3/3.2.4/3.2.5 (High) | sc-audit Fase 4 Aritmetika (PERKUAT — hanya bagian ill-conditioned); invariant-testing Catatan desain (+butir) |
| C-06 | Gate / check yang mempercayai nilai turunan yang sudah rusak | Monetrix M-01 (Medium); Mercury 3.3.1 (Medium) | sc-audit Fase 4 (+butir baru); bounty-hunter Fase 3 (+butir 14) |
| C-07 | DoS / griefing via jalur yang tidak butuh modal | Mercury 3.1.3 (Critical); 3.2.1/3.2.2 (High) | sc-audit Fase 4 (+butir baru); bounty-hunter Fase 2 Tier 3 (PERKUAT — perluasan P-07) |
| F-01 | Framing severity yang menang: angka + negative check + pre-kondisi + attack path + distinctness + PoC | Korpus §4 (Monetrix, Mercury, EigenLayer) | bounty-hunter Fase 5 (PERKUAT); sc-audit Fase 2 item 3 (PERKUAT) |
| M-01 | Kasus batas manual ala Halmos | methodologies/halmos-symbolic-testing.md §5 | invariant-testing Catatan desain (+butir) + Checklist (+butir) |
| M-02 | Korpus + minimisasi urutan gagal ala Echidna/Medusa | methodologies/echidna-medusa-property-fuzzing.md §4, §7 | invariant-testing Catatan desain (+butir) + Checklist (+butir) |
| M-03 | Uji tautologi / vakum ala trailofbits-skills | methodologies/trailofbits-skills-rewrite.md Bagian B | invariant-testing Catatan desain (+butir) + Checklist (+butir); sc-audit Fase 2 item 2 (PERKUAT) |
| M-04 | Inspeksi visual + anti-rasionalisasi ala trailofbits-skills | methodologies/trailofbits-skills-rewrite.md Bagian A | sc-audit Fase 3 (+paragraf); bounty-hunter Fase 3 (+butir 15) |

---

## C-01 — Akuntansi satu sisi: aset dikredit, kewajiban diabaikan

**Sumber:** Code4rena Monetrix M-01 (Medium — satu-satunya temuan dari
1.726 baris Solidity; 39 warden menemukan hal yang sama); Mercury 3.1.5
(Critical — utang tanpa backing saat kreasi pool); Mercury 3.3.1
(Medium — allocated reserves over-reported); Mercury 3.3.2 (Medium —
outstanding reserves tidak dihitung dalam yield).
**Root cause:** fungsi yang menghitung "berapa yang kami punya" hanya
mendekode/menghitung sisi aset dan membuang sisi kewajiban. Monetrix:
`PrecompileReader.suppliedBalance()` membaca precompile Hyperliquid
`0x811` yang mengenkode BORROW **dan** SUPPLY, tapi hanya mendekode
field ke-4 (`supply.value`) dan membuang `borrow.basis` /
`borrow.value` — lalu `MonetrixAccountant._readL1Backing()` mengkredit
semua PM-supplied sebagai backing positif tanpa pengurangan borrow di
mana pun → `totalBackingSigned()` terinflasi → Gate 3 lolos atas surplus
palsu → `distributeYield()` mencetak USDM nyata. Angka: ≈ **2.876 USDM
per jendela settlement 21 jam** (≈ 2.013 USDM ke sUSDM). Tidak butuh
privilege, reentrancy, atau flash loan — cukup jadi holder sUSDM biasa.
**Pola:** setiap fungsi yang menghitung backing/saldo/kekayaan — tanya
apakah ada sisi kewajiban/utang/klaim tertunda yang TIDAK dikurangi,
khususnya saat data datang dari sumber eksternal (precompile, oracle,
L1/L2) yang mengenkode aset DAN liabilitas dalam satu respons.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Alamat
counterfactual (CREATE/CREATE2)":**

```text
- **Akuntansi satu sisi — aset dikredit, kewajiban diabaikan.**
  Setiap fungsi yang menghitung "berapa yang kami punya" (backing,
  surplus, total aset, yield yang bisa didistribusikan): tanya apakah
  ada sisi kewajiban / utang / klaim tertunda yang TIDAK dikurangi.
  Khususnya saat data datang dari sumber eksternal (precompile,
  oracle, L1/L2, sistem lain) yang mengenkode aset DAN liabilitas
  dalam satu respons — periksa SEMUA field yang didekode dan tanya
  field mana yang dibuang. (Monetrix M-01: `suppliedBalance()` hanya
  mendekode `supply.value` dari precompile 0x811 dan membuang
  `borrow.basis`/`borrow.value` → backing terinflasi → Gate 3 lolos
  atas surplus palsu → ≈ 2.876 USDM/21 jam dicetak dari ketiadaan;
  Mercury 3.1.5: reserves dibuat `R + D` tapi hanya `R` yang diambil
  → selisih `D` adalah utang tanpa backing.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 2, butir "Accounting
collateral/utang yang salah setelah operasi parsial" (PERKUAT):**

```text
- Accounting collateral/utang yang salah setelah operasi parsial — termasuk akuntansi satu sisi: fungsi yang mengkredit aset tanpa mengurangi kewajiban/utang yang datang dari sumber yang sama (Monetrix M-01: field borrow dibuang saat decode precompile; Mercury 3.1.5: utang tanpa backing). Tulis persamaan ledger-nya; selisih = kandidat.
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant snapshot: snapshot DULU, baru mint"):**

```text
- **Invariant akuntansi dua sisi: aset − liabilitas, bukan aset
  saja.** Bila protokol membaca angka dari sumber eksternal yang
  mengenkode aset DAN liabilitas (precompile, oracle, L1/L2), tulis
  invariant atas nilai NETO ("totalBacking == aset − liabilitas")
  dan uji dengan handler yang membuat sisi kewajiban lebih besar
  dari sisi aset — gate yang lolos atas surplus palsu adalah
  buktinya. (Monetrix M-01: ≈ 2.876 USDM/21 jam.)
```

---

## C-02 — Double-counting / double-spend saat inisialisasi

**Sumber:** Mercury 3.1.4 (Critical — kolateral awal dipakai 2×,
diambil dari creator hanya 1×) dan 3.1.5 (Critical — reserves dibuat
`initialPoolReserves + initialDebt`, diambil hanya
`initialPoolReserves`).
**Root cause:** jalur kreasi / setup / inisialisasi adalah tempat
paling subur untuk "uang muncul dari ketiadaan": satu dana dipakai
sebagai dua klaim yang berbeda, atau klaim dibuat tanpa penarikan dana
yang setara. Mercury 3.1.4: `initialCollateral` dipakai pertama sebagai
`pool.totalBTokens`, lalu dalam sistem kredit — tapi diambil dari
creator hanya sekali → kolateral "unbacked". Bila
`initialCollateral = 0`, jalur inisialisasi posisi kredit tidak terpicu
sama sekali, sehingga `BCredit.borrow` meminjamkan reserves yang bukan
milik pool itu → insolvensi.
**Pelajaran misi (dari korpus §3):** di Sparklend, hipotesis yang gagal
sebagian besar karena ledger-nya SEIMBANG — pola ini hanya menang bila
ledger-nya benar-benar tidak seimbang. Buktikan dengan persamaan,
jangan asumsi.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Akuntansi satu
sisi" (C-01):**

```text
- **Double-counting saat inisialisasi.** Jalur create / setup /
  initialize adalah tempat paling subur untuk "uang muncul dari
  ketiadaan": satu dana dipakai sebagai dua klaim yang berbeda, atau
  klaim dibuat tanpa penarikan dana yang setara. Untuk SETIAP fungsi
  create/initialize, tulis persamaan ledger-nya: dana apa yang masuk,
  klaim apa yang keluar — apakah keduanya seimbang, SATU PER SATU?
  Periksa juga cabang `initialX == 0`: bila jalur inisialisasi tidak
  terpicu sama sekali, apakah fungsi lain tetap mengasumsikan state
  itu sudah ada? (Mercury 3.1.4: `initialCollateral` dipakai 2×,
  diambil 1× → kolateral unbacked; 3.1.5: reserves dibuat `R + D`,
  diambil `R` → selisih `D` utang tanpa backing.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 12 (setelah butir
11 "Lacak jalur delegasi tersembunyi"):**

```text
12. **Tulis persamaan ledger untuk setiap fungsi create/initialize.**
    Dana apa yang masuk, klaim apa yang keluar — apakah keduanya
    seimbang satu per satu? Selisih = kandidat. Periksa cabang
    `initialX == 0`: jalur inisialisasi yang tidak terpicu bisa
    membuat fungsi lain meminjamkan dana yang bukan miliknya.
    (Mercury 3.1.4, 3.1.5.)
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru (setelah
"Bila protokol membaca state yang sama 2×..."):**

```text
- [ ] Untuk setiap fungsi create/initialize, ada invariant
  "dana masuk == klaim keluar" — termasuk cabang `initialX == 0`
  (Mercury 3.1.4, 3.1.5).
```

---

## C-03 — Dana bersama tanpa pemisahan kepemilikan (contagion)

**Sumber:** Mercury 3.1.4 (Critical — Pool 2 jahat menguras Pool 1).
**Root cause:** reserves disimpan di saldo kontrak, bukan vault
per-pool. `giveReserves` mentransfer dari **saldo kontrak** tanpa
memeriksa reserves milik pool mana — jadi Pool 2 yang dibuat penyerang
(reserve WETH yang sama + merkle root berisi posisi kolateral 400.000
ether, utang 0) bisa `claimCredit` lalu `borrow` lalu `giveReserves`
dan menguras reserves Pool 1 juga. Dua cacat bergabung: (a)
double-counting kolateral awal (C-02); (b) dana bersama tanpa
pemisahan kepemilikan.
**Pola:** bila banyak pool / vault / akun berbagi satu saldo token di
satu kontrak, setiap penarikan WAJIB memeriksa "apakah dana ini milik
pemohon?" Tanpa itu, satu pool jahat / satu akun yang dibuat khusus
menjadi selang ke dana semua orang. Cari `balanceOf(address(this))`
yang dipakai sebagai sumber kebenaran tanpa alokasi per pemilik.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah
"Double-counting saat inisialisasi" (C-02):**

```text
- **Dana bersama tanpa pemisahan kepemilikan (contagion).** Bila
  banyak pool / vault / akun berbagi satu saldo token di satu
  kontrak, setiap penarikan WAJIB memeriksa "apakah dana ini milik
  pemohon?" Cari `balanceOf(address(this))` yang dipakai sebagai
  sumber kebenaran tanpa alokasi per pemilik — satu pool jahat /
  satu akun yang dibuat khusus menjadi selang ke dana semua orang.
  (Mercury 3.1.4: Pool 2 jahat `claimCredit` + `borrow` +
  `giveReserves` dari saldo kontrak → menguras reserves Pool 1 juga.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 2, butir baru (setelah
"Proxy upgradeable"):**

```text
- Dana bersama tanpa pemisahan kepemilikan — pool/vault yang berbagi satu saldo kontrak tanpa cek kepemilikan per-pool; satu pool jahat bisa menguras pool lain (Mercury 3.1.4).
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant akuntansi dua sisi"):**

```text
- **Invariant kepemilikan per-pool: saldo per-pool == alokasi
  per-pool.** Bila beberapa pool berbagi satu saldo token di satu
  kontrak, tulis invariant "penarikan dari pool P tidak boleh
  melebihi alokasi pool P" dan uji dengan handler yang membuat pool
  kedua dengan reserve token yang sama lalu menarik dari pool
  pertama. (Mercury 3.1.4.)
```

---

## C-04 — Boundary off-by-one + urutan eksekusi yang diasumsikan

**Sumber:** Cantina EigenLayer 3.1.1 (High — satu-satunya High dari 71
isu; `>` vs `>=` + EIP-4895 → **32 ETH hilang permanen**); Mercury
3.1.3 (Critical — `beforeInitialize` tanpa validasi → frontrun
inisialisasi pool = DoS permanen).
**Root cause:** bug satu karakter di boundary (`>` vs `>=`) MENANG bila
digabung dengan fakta urutan eksekusi yang benar. EigenLayer:
`activateRestaking` memanggil `_processWithdrawalBeforeRestaking` yang
menetapkan `mostRecentWithdrawalTimestamp = block.timestamp` dan
menyapu saldo — tapi menurut EIP-4895, withdrawal beacon chain
dieksekusi **setelah semua transaksi pengguna** di blok yang sama, jadi
withdrawal yang masuk di blok yang sama dikreditkan SETELAH sweep dan
proof-nya membawa timestamp **sama dengan** yang tersimpan, yang ditolak
perbandingan ketat `>`. Rekomendasi: satu karakter, `>=`.
**Pelajaran framing:** tidak butuh logika rumit — butuh membaca
spesifikasi eksternal (EIP-4895, urutan blok) dan bertanya "apa yang
terjadi di TEPI, di blok yang sama, di timestamp yang sama?"
**Bedanya dengan fase J P-17:** P-17 mencakup constructor typo +
underflow pra-0.8. Yang baru di sini adalah perbandingan boundary
(`>` vs `>=`) + asumsi urutan eksekusi lintas-layer — bukan typo,
bukan aritmetika.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Control flow
berbasis tipe error / try-catch":**

```text
- **Boundary off-by-one + urutan eksekusi yang diasumsikan.** Untuk
  setiap `require` perbandingan, tanya: kasus kesetaraan (`==`)
  masuk ke cabang mana — dan apakah itu benar? Untuk setiap
  inisialisasi satu-kali, tanya: siapa yang bisa memanggilnya lebih
  dulu, dan apa yang terjadi bila bukan pemilik yang sah? Baca
  spesifikasi eksternal (EIP, docs) untuk urutan eksekusi lintas
  layer — apa yang terjadi bila dua peristiwa terjadi di blok /
  timestamp / nilai yang SAMA? (EigenLayer 3.1.1: `>` vs `>=` +
  EIP-4895 → 32 ETH hilang permanen; Mercury 3.1.3: frontrun
  `beforeInitialize` → DoS permanen pool.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 13 (setelah butir
12 dari C-02):**

```text
13. **Uji kesetaraan di setiap perbandingan + urutan eksekusi
    lintas-layer.** Untuk setiap `>` / `>=` / `<` / `<=`, tanya apa
    yang terjadi bila kedua sisi SAMA. Baca spesifikasi eksternal
    (EIP, docs) untuk urutan eksekusi — peristiwa yang terjadi di
    blok/timestamp yang sama bisa lolos dari asumsi kode. (EigenLayer
    3.1.1: 32 ETH hilang permanen karena `>` vs `>=`.)
```

---

## C-05 — Matematika ill-conditioned: benar secara aljabar, salah secara numerik

**Sumber:** Mercury 3.1.1 (Critical — `(a−b)/(c−d)` ill-conditioned,
catastrophic cancellation, penyerang bayar setengah harga); Mercury
3.2.3 (High — divide-before-multiply); 3.2.4/3.2.5 (High — arah
pembulatan); 3.4.2/3.4.5 (Low — arah pembulatan). **6 dari 28 isu
Mercury adalah presisi/pembulatan — kategori paling padat di laporan
itu.**
**Root cause:** rumus yang benar di kertas kehilangan semua presisi
saat selisih dua bilangan besar yang berdekatan (`(a−b)/(c−d)` saat
`a → b` dan `c → d`: tidak ada cara menghitungnya dengan presisi
tertentu saat selisih mendekati unit minimal 1e-18). PoC Foundry:
`quoteTokensForReservesOut` membulatkan `Pbook` ke bawah; selisih
`P_0 − Pbook = 1` menjadi `2` setelah pembulatan → `K` menjadi 2×
lipat → **setengah token yang dibutuhkan untuk membeli jumlah reserves
yang sama**. Perilaku yang diharapkan: hasil harus konvergen ke
bookPrice saat harga berdekatan (ada fallback zero-convexity), bukan
divergen ke tak hingga.
**Batas dengan yang sudah ada (jangan duplikasi):** divide-before-
multiply dan arah pembulatan SUDAH tercakup di skill (fase J mencatat
"Rounding/presisi" sebagai sudah tercakup; skill `fixed-point-rounding`
batch 6). Yang BARU di sini hanya bagian ill-conditioned /
catastrophic cancellation + titik singular — karena itu usulan di bawah
hanya menambah sub-butir itu, bukan menulis ulang rounding.

**USULAN TEKS — sc-audit, Fase 4, butir "Aritmetika / presisi"
(PERKUAT — tambah sub-butir setelah sub-butir underflow array):**

```text
  - **Rumus ill-conditioned / catastrophic cancellation.** Rumus
    yang benar secara aljabar bisa salah total secara numerik di
    dekat titik singular: selisih dua harga besar yang berdekatan
    (`(a−b)/(c−d)`) kehilangan semua presisi saat selisih mendekati
    unit minimal. Uji: apa yang terjadi saat dua harga / dua jumlah
    menjadi SAMA atau hampir sama? Hasil harus konvergen ke harga
    buku saat harga berdekatan, bukan divergen. (Mercury 3.1.1:
    pembulatan mengubah selisih 1 menjadi 2 → `K` 2× lipat →
    penyerang membayar setengah harga.)
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant kepemilikan per-pool"):**

```text
- **Invariant di dekat titik singular.** Untuk rumus yang memakai
  selisih dua nilai berdekatan (`(a−b)/(c−d)`), tulis invariant
  "harga tidak boleh menyimpang > X% dari harga buku" dan fuzz
  dengan handler yang mendorong kedua nilai ke arah yang sama
  sampai selisihnya mendekati nol — di situlah catastrophic
  cancellation bersembunyi. (Mercury 3.1.1: penyerang membayar
  setengah harga.)
```

---

## C-06 — Gate / check yang mempercayai nilai turunan yang sudah rusak

**Sumber:** Monetrix M-01 (Medium — Gate 3 + Gate 4 lolos karena
`totalBackingSigned()` sudah terinflasi); Mercury 3.3.1 (Medium —
allocated reserves over-reported → keputusan salah).
**Root cause:** check keamanan (`require`, gate, cap, batas) hanya
sekuat INPUT-nya. Bila inputnya adalah nilai yang dihitung dari
akuntansi yang salah, gate itu teater. Laporan pemenang membuktikan ini
secara eksplisit (bagian "Negative Check" Monetrix: Gate 3 TIDAK
mencegah karena percaya pada `totalBackingSigned()` yang sudah
terinflasi; Gate 4 TIDAK mencegah karena hanya membatasi laju, bukan
memverifikasi liabilitas neto; reentrancy TIDAK relevan karena ini
omisi akuntansi).
**Kait ke metode misi:** ini pertanyaan yang sama dengan gate
7-pertanyaan misi Q1 ("apakah asumsi yang mendasari benar?") — tapi
di sini dalam bentuk yang bisa diaudit: lacak asal angka setiap gate.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Dana bersama
tanpa pemisahan kepemilikan" (C-03):**

```text
- **Gate yang mempercayai nilai turunan yang sudah rusak.** Check
  keamanan (`require`, gate, cap, batas) hanya sekuat INPUT-nya.
  Untuk setiap gate, lacak asal angkanya: bila angka itu dihitung
  dari akuntansi (backing, surplus, reserves), uji akuntansinya
  DULU — bila sumber angka itu salah, gate itu teater. Tulis
  negative check eksplisit: pertahanan mana yang ada, dan mengapa
  masing-masing TIDAK mencegah temuan ini. (Monetrix M-01: Gate 3
  lolos karena `totalBackingSigned()` terinflasi; Gate 4 hanya
  membatasi laju; Mercury 3.3.1: reserves over-reported →
  keputusan salah.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 14 (setelah butir
13 dari C-04):**

```text
14. **Lacak asal angka setiap gate sebelum percaya gate itu.**
    Bila gate memeriksa angka yang dihitung dari akuntansi, uji
    akuntansinya dulu — gate yang memeriksa angka salah adalah
    teater. Tulis negative check: pertahanan mana yang ada, dan
    mengapa masing-masing tidak mencegah temuan ini. (Monetrix M-01.)
```

---

## C-07 — DoS / griefing via jalur yang tidak butuh modal

**Sumber:** Mercury 3.1.3 (Critical — frontrun `beforeInitialize` =
DoS permanen pool); 3.2.1 (High — DoS `claimCredit` karena pembayaran
utang eksternal untuk `address(this)`); 3.2.2 (High — salt truncation
di `createBToken` → DoS saat deploy ulang untuk sender yang sama).
**Root cause:** DoS yang MENANG adalah yang permanen / tidak bisa
dipulihkan, atau yang memblokir fungsi inti dengan biaya nol. DoS
sementara / griefing kecil biasanya Low. Tiga mekanisme di sini:
(a) fungsi satu-kali yang bisa didahului orang lain (frontrun init);
(b) operasi yang gagal bila ada yang mengirim dana/utang ke alamat
kontrak lebih dulu (asumsi "saldo kontrak = milik kami" yang salah);
(c) salt yang terpotong sehingga deploy ulang untuk sender yang sama
bertabrakan.
**Bedanya dengan fase J P-07:** P-07 adalah push-payment DoS
(penerima yang menolak pembayaran melumpuhkan fungsi inti). Yang baru
di sini adalah tiga mekanisme di atas — karena itu usulan di bawah
ditulis sebagai PERLUASAN butir P-07, bukan butir tandingan.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Gas griefing +
aturan EIP-150 (63/64)":**

```text
- **DoS tanpa modal — init yang didahului, asumsi saldo kontrak,
  salt yang terpotong.** (a) Fungsi satu-kali apa yang bisa
  dipanggil orang lain lebih dulu? Frontrun inisialisasi = DoS
  permanen bila tidak ada jalan pemulihan. (b) Operasi apa yang gagal
  bila ada yang mengirim dana / utang ke alamat kontrak lebih dulu?
  Asumsi "saldo kontrak = milik kami" salah bila siapa pun bisa
  menambah saldo/utang eksternal. (c) Salt / identifier apa yang
  terpotong sehingga dua deployment berbeda bertabrakan? (Mercury
  3.1.3: frontrun `beforeInitialize` → DoS permanen; 3.2.1: DoS
  `claimCredit` via pembayaran utang eksternal untuk `address(this)`;
  3.2.2: salt truncation → DoS deploy ulang.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 3, butir "Push-payment
DoS" (PERKUAT — perluasan dari fase J P-07):**

```text
- Push-payment DoS — penerima yang menolak pembayaran melumpuhkan fungsi inti (Ethernaut #9 King). Cari pola `transfer`/`send`/`call` ke alamat pilihan pihak lain di tengah alur. Perluasan: DoS tanpa modal — frontrun fungsi init satu-kali (Mercury 3.1.3: DoS permanen pool), operasi yang gagal bila ada yang mengirim dana/utang ke alamat kontrak lebih dulu (Mercury 3.2.1), salt yang terpotong sehingga deploy ulang bertabrakan (Mercury 3.2.2).
```

---

## F-01 — Framing severity yang menang: angka + negative check + pre-kondisi + attack path + distinctness + PoC

**Sumber:** korpus §4 — pola framing yang berulang pada temuan yang
menang di ketiga laporan (Monetrix, Mercury, EigenLayer).
**Isi:** (1) Kuantifikasi dampak dalam angka, bukan kata sifat
(Monetrix: "~2.876 USDM per jendela 21 jam"; Mercury: "penyerang
membayar setengah harga" + PoC Foundry angka eksak; EigenLayer: "32
ETH hilang permanen"). (2) Negative check — buktikan pertahanan yang
ada TIDAK bekerja (Monetrix punya bagian khusus: Gate 3 tidak mencegah,
Gate 4 tidak mencegah, reentrancy tidak relevan, bukan duplikat V12).
(3) Pre-conditions eksplisit (internal + eksternal) dengan argumen
tiap pre-kondisi itu REALISTIS (auto-borrow adalah fitur normal, bukan
mode gagal eksotis) — likelihood dinilai dari realisme pre-kondisi,
bukan dari "mungkinkah secara teori". (4) Attack path
langkah-demi-langkah yang bisa diikuti. (5) Distinctness — buktikan ini
BUKAN duplikat (Monetrix membedakan diri dari 4 temuan V12). (6) PoC
yang berjalan, dengan angka. (7) Severity = Impact × Likelihood —
jangan menaikkan severity sendiri tanpa bukti likelihood; framing yang
jujur (Medium dengan impact High yang dijelaskan) MENANG; klaim
Critical yang tidak didukung likelihood DITOLAK.
**Bedanya dengan yang sudah ada:** bounty-hunter Fase 5 sudah punya
"Kuantifikasi dampak" (satu baris) — usulan di bawah memperluasnya
menjadi checklist framing lengkap. sc-audit Fase 2 item 3 sudah punya
"Aset berisiko" — usulan di bawah menambah kalimat framing.

**USULAN TEKS — bounty-hunter, Fase 5, setelah butir "Kuantifikasi
dampak" (PERKUAT):**

```text
- **Kuantifikasi dampak**: aset berisiko, biaya serangan yang realistis, profit — dalam ANGKA per jendela waktu, bukan kata sifat ("≈ 2.876 USDM per jendela 21 jam", "32 ETH hilang permanen", "penyerang membayar setengah harga"). Laporan yang hanya berkata "berisiko" kalah dari laporan yang berkata "sebanyak ini, secepat ini".
- **Framing yang menang (checklist sebelum submit):** (1) angka dampak per jendela waktu; (2) negative check — pertahanan mana yang ada dan mengapa masing-masing TIDAK mencegah; (3) pre-kondisi eksplisit (internal + eksternal) dengan alasan tiap pre-kondisi REALISTIS; (4) attack path langkah-demi-langkah yang bisa diikuti; (5) distinctness — buktikan ini BUKAN duplikat temuan lain; (6) PoC yang berjalan, dengan angka. Severity = Impact × Likelihood — jangan naikkan severity tanpa bukti likelihood; framing jujur (Medium dengan impact High yang dijelaskan) MENANG, klaim Critical tanpa dukungan likelihood DITOLAK. (Korpus C4/Cantina §4.)
```

**USULAN TEKS — sc-audit, Fase 2, item 3 "Aset berisiko"
(PERKUAT — tambah kalimat):**

```text
   nilai maksimum yang terekspos. Kuantifikasi dalam angka per
   jendela waktu + tulis negative check (mengapa pertahanan yang ada
   tidak mencegah) — itu yang membedakan temuan yang menang dari
   temuan yang ditolak. (Korpus C4/Cantina §4.)
```

---

## M-01 — Kasus batas manual ala Halmos (disiplin, bukan tool)

**Sumber:** `methodologies/halmos-symbolic-testing.md` §5 — disiplin
berpikir pengujian simbolik yang diterapkan dengan Foundry 1.9.0,
tanpa menginstal Halmos (AGPL-3.0).
**Inti:** fuzzing berbasis sampel bisa tidak pernah memilih nilai
langka yang memicu cabang tertentu. Disiplin Halmos: (1) untuk tiap
properti invariant, buat daftar kasus batas manual — nilai 0, 1,
maksimum, maksimum−1, alamat nol, alamat yang sama dengan alamat lain,
saldo tepat sama dengan jumlah, kombinasi dua variabel yang berimpit;
(2) uji tiap kasus batas secara deterministik (satu tes Foundry per
kasus, bukan fuzz) sehingga tiap kasus selalu dijalankan; (3) audit
semua `assume` di tes fuzz — syarat yang terlalu kuat mengecualikan
input valid dan memberi rasa aman palsu; (4) pisahkan properti
"terbukti sampel" dari "terbukti menyeluruh" — jangan pernah klaim
properti terbukti hanya karena fuzzing tidak menemukan pelanggaran,
catat jujur: properti X diuji dengan N panggilan fuzz + M kasus batas
deterministik; (5) tanyakan untuk tiap properti baru: "kombinasi input
apa yang akan dilaporkan solver sebagai contoh tandingan bila properti
ini salah?" — lalu tulis tes untuk kombinasi itu lebih dulu.
**Jebakan yang diingatkan:** properti yang ditulis asal-asalan bisa
gagal pada kasus tepi (contoh Halmos: transfer ke diri sendiri —
pengirim == penerima — membuat asersi "saldo pengirim berkurang,
penerima bertambah" gagal; yang salah propertinya, bukan kontraknya).
**Bedanya dengan C-04:** C-04 adalah "apa" yang diuji (kasus
kesetaraan + urutan eksekusi lintas-layer); M-01 adalah "bagaimana"
cara mengujinya secara sistematis (daftar kasus batas + tes
deterministik + audit `assume`).

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant di dekat titik singular"):**

```text
- **Kasus batas manual ala Halmos (disiplin, bukan tool).** Fuzzing
  berbasis sampel bisa tidak pernah memilih nilai langka yang memicu
  cabang tertentu. Untuk tiap properti invariant, buat daftar kasus
  batas manual — nilai 0, 1, maksimum, maksimum−1, alamat nol, alamat
  yang sama dengan alamat lain, saldo tepat sama dengan jumlah,
  kombinasi dua variabel yang berimpit — dan uji tiap kasus secara
  deterministik (satu tes Foundry per kasus, bukan fuzz). Audit semua
  `assume`: syarat yang terlalu kuat mengecualikan input valid dan
  memberi rasa aman palsu. Jangan pernah klaim properti terbukti
  hanya karena fuzzing tidak menemukan pelanggaran — catat jujur:
  properti X diuji dengan N panggilan fuzz + M kasus batas
  deterministik. (Metodologi Halmos, fase B.)
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru (setelah
"Untuk setiap fungsi create/initialize..."):**

```text
- [ ] Daftar kasus batas manual (0, 1, maksimum, maksimum−1, alamat
  nol, alamat yang sama, saldo == jumlah) sudah ditulis sebagai tes
  deterministik — bukan hanya fuzz (disiplin Halmos).
- [ ] Semua `assume` sudah diaudit: tidak ada yang menyaring input
  valid, dan tidak ada properti yang lolos dengan nol kasus yang
  benar-benar dijalankan.
```

---

## M-02 — Korpus + minimisasi urutan gagal ala Echidna/Medusa (disiplin, bukan tool)

**Sumber:** `methodologies/echidna-medusa-property-fuzzing.md` §4, §7 —
disiplin fuzzing berbasis properti yang diterapkan di atas Foundry
1.9.0, tanpa menginstal Echidna/Medusa (AGPL-3.0).
**Inti:** (1) Pisahkan properti fungsi dan sistem secara eksplisit —
beri label pada tiap invariant: fungsi atau sistem; properti sistem
diuji dengan urutan panjang dan semua fungsi. (2) Korpus sebagai
artefak — simpan urutan panggilan yang menambah coverage sebagai
skenario tes deterministik yang tercatat (bukan sekadar angka coverage);
bila suatu urutan menemukan cabang baru, abadikan sebagai tes regresi.
(3) Minimisasi urutan gagal — bila invariant gagal, pangkas urutan
secara manual: buang satu panggilan demi satu; bila invariant tetap
gagal, panggilan itu tidak relevan — buang; ulangi sampai tersisa
urutan terpendek yang masih gagal. Urutan minimal adalah separuh dari
laporan bug yang baik. (4) Mode optimasi — gunakan invariant
optimization Foundry untuk memaksimalkan metrik (slippage terburuk,
error pembulatan terbesar, selisih saldo terbesar), bukan hanya
memeriksa benar/salah. (5) Seed dari unit test — jadikan skenario unit
test penting sebagai urutan awal handler invariant.
**Bedanya dengan yang sudah ada:** invariant-testing sudah punya
"Urutan gagal yang ter-shrink sudah dibaca" di Checklist — usulan di
bawah memperluasnya menjadi disiplin korpus (simpan urutan penambah
coverage sebagai tes regresi) + minimisasi manual langkah-demi-langkah
+ label fungsi-vs-sistem + mode optimasi.

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Kasus batas manual ala Halmos"):**

```text
- **Korpus + minimisasi ala Echidna/Medusa (disiplin, bukan tool).**
  (a) Labeli tiap invariant: fungsi atau sistem — properti sistem
  diuji dengan urutan panjang dan semua fungsi. (b) Simpan urutan
  panggilan yang menambah coverage sebagai skenario tes deterministik
  yang tercatat; bila suatu urutan menemukan cabang baru, abadikan
  sebagai tes regresi. (c) Bila invariant gagal, minimalkan urutan
  secara manual: buang satu panggilan demi satu; bila invariant
  tetap gagal, panggilan itu tidak relevan — ulangi sampai tersisa
  urutan terpendek yang masih gagal; urutan minimal adalah separuh
  dari laporan bug yang baik. (d) Gunakan mode optimasi Foundry
  untuk memaksimalkan metrik (slippage terburuk, error pembulatan
  terbesar), bukan hanya memeriksa benar/salah. (Metodologi
  Echidna/Medusa, fase B.)
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru (setelah
butir kasus batas M-01):**

```text
- [ ] Tiap invariant sudah dilabeli fungsi atau sistem.
- [ ] Urutan gagal sudah diminimalkan manual sampai tersisa urutan
  terpendek yang masih gagal — dan urutan itu yang jadi PoC.
- [ ] Urutan penambah coverage sudah diabadikan sebagai tes regresi
  deterministik (bukan sekadar angka coverage).
```

---

## M-03 — Uji tautologi / vakum ala trailofbits-skills (disiplin, bukan tool)

**Sumber:** `methodologies/trailofbits-skills-rewrite.md` Bagian B —
katalog properti pengujian berbasis properti (CC-BY-SA-4.0, tulis ulang
kata sendiri).
**Inti:** dua cara properti menjadi tidak menegaskan apa pun. (1)
**Tautologi** — asersi yang mengulang implementasi (mis. menguji
`add(a,b) == a+b` dengan implementasi yang sama persis; bug yang sama
ada di kedua sisi, sehingga tes tidak akan pernah gagal). Pilih properti
yang membatasi fungsi *tanpa* menghitung ulang fungsinya. Pengecualian:
`f(x) == f(x)` adalah properti determinisme yang sah bila `f` tidak
jelas murni. (2) **Vakum** — `assume` yang menyaring hampir semua input
membuat tes lolos tanpa menguji apa pun; `assume` yang bertentangan
dengan dirinya sendiri membuat tes lolos setelah menjalankan nol kasus.
Solusinya: dorong batasan ke dalam strategi generator, agar generator
langsung menghasilkan input yang valid — bukan menyaring input acak
setelahnya. Urutan kekuatan properti (lemah ke kuat): tanpa crash →
preservasi tipe → invariant → idempotence → roundtrip/oracle. Tegaskan
properti **terkuat** yang didukung kode.
**Bedanya dengan M-01:** M-01 soal nilai batas yang terlewat; M-03 soal
properti yang strukturnya tidak bisa gagal. Keduanya melengkapi: properti
yang lolos M-03 (bukan tautologi, tidak vakum) masih harus lolos M-01
(dicek di kasus batas).

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Korpus + minimisasi ala Echidna/Medusa"):**

```text
- **Uji tautologi / vakum untuk tiap properti (ala
  trailofbits-skills).** Dua pertanyaan sebelum mempercayai sebuah
  invariant: (1) "Apakah ini tautologi?" — asersi yang mengulang
  implementasi (`add(a,b) == a+b` dengan implementasi yang sama)
  tidak akan pernah gagal karena bug yang sama ada di kedua sisi;
  pilih properti yang membatasi fungsi TANPA menghitung ulang
  fungsinya. (2) "Apakah `assume`-nya vakum?" — `assume` yang
  menyaring hampir semua input membuat tes lolos tanpa menguji apa
  pun; `assume` yang bertentangan dengan dirinya sendiri membuat tes
  lolos setelah nol kasus. Tegaskan properti TERKUAT yang didukung
  kode (tanpa crash → preservasi tipe → invariant → idempotence →
  roundtrip/oracle). (Metodologi trailofbits-skills, fase B.)
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru (setelah
butir korpus M-02):**

```text
- [ ] Tiap invariant lolos dua pertanyaan: bukan tautologi (tidak
  mengulang implementasi) dan `assume`-nya tidak vakum (kasus yang
  benar-benar dijalankan > 0 dan mencakup wilayah yang relevan).
```

**USULAN TEKS — sc-audit, Fase 2, item 2 "Invariant protokol"
(PERKUAT — tambah kalimat setelah "(INV1, ...)"):**

```text
   Tiap invariant harus lolos dua pertanyaan sebelum dipercaya:
   "apakah ini tautologi?" (asersi yang mengulang implementasi tidak
   akan pernah gagal) dan "apakah `assume`/pre-kondisinya vakum?"
   (menyaring hampir semua kasus). (Metodologi trailofbits-skills,
   fase B.)
```

---

## M-04 — Inspeksi visual + anti-rasionalisasi ala trailofbits-skills

**Sumber:** `methodologies/trailofbits-skills-rewrite.md` Bagian A —
alur kerja aman lima langkah (CC-BY-SA-4.0, tulis ulang kata sendiri).
**Inti:** (1) Inspeksi visual — buat tiga diagram dan periksa satu per
satu: **graf pewarisan** (mengungkap shadowing dan masalah linearisasi
C3), **ringkasan fungsi** (visibilitas dan kontrol akses tiap fungsi —
fungsi `onlyOwner` yang ternyata bisa dipanggil siapa saja langsung
terlihat), **variabel dan otorisasi** (siapa yang bisa menulis tiap
variabel state — variabel kritis yang bisa ditulis banyak pihak
langsung terlihat). Diagram mengungkap pola yang tidak terlihat dari
teks. (2) Anti-rasionalisasi — prinsip: **"tidak berlaku" tanpa
verifikasi sama dengan kerentanan yang terlewat.** Setiap langkah yang
dilewati harus dibuktikan dengan pencarian eksplisit di codebase, bukan
asumsi. Contoh: "tidak ada token, lewati cek ERC" adalah kesalahan bila
ternyata ada interaksi transfer token di suatu sudut kode. "Tidak ada
interaksi DeFi, lewati cek oracle/flash loan" adalah kesalahan bila
ternyata ada price feed di suatu tempat. Dan: jangan mengganti eksekusi
workflow dengan nasihat generik — setiap temuan harus punya referensi
file dan baris.
**Bedanya dengan yang sudah ada:** sc-audit Fase 3 sudah mengenumerasi
attack surface per fungsi, tapi belum memakai tiga diagram sebagai alat
pemeriksaan; bounty-hunter Fase 3 item 5 sudah punya falsifikasi
("coba BUNUH hipotesismu"), tapi belum punya prinsip anti-rasionalisasi
untuk langkah yang DILEWATI. Keduanya adalah tambahan, bukan duplikasi.

**USULAN TEKS — sc-audit, Fase 3, paragraf baru (setelah paragraf
enumerasi attack surface, sebelum "## Fase 4"):**

```text
**Inspeksi visual (tiga diagram).** Sebelum deep review, buat dan
periksa: (1) **graf pewarisan** — mengungkap shadowing dan masalah
linearisasi C3; (2) **ringkasan fungsi** — visibilitas dan kontrol
akses tiap fungsi (fungsi `onlyOwner` yang ternyata bisa dipanggil
siapa saja langsung terlihat); (3) **variabel dan otorisasi** — siapa
yang bisa menulis tiap variabel state (variabel kritis yang bisa
ditulis banyak pihak langsung terlihat). Diagram mengungkap pola yang
tidak terlihat dari teks. (Metodologi trailofbits-skills, fase B.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 15 (setelah butir
14 dari C-06):**

```text
15. **Jangan lewati pemeriksaan dengan alasan "tidak berlaku" tanpa
    bukti pencarian eksplisit.** "Tidak ada token, lewati cek ERC"
    adalah kesalahan bila ternyata ada interaksi transfer token di
    suatu sudut kode; "tidak ada interaksi DeFi, lewati cek
    oracle/flash loan" adalah kesalahan bila ternyata ada price feed
    di suatu tempat. Setiap langkah yang dilewati harus dibuktikan
    dengan grep/pencarian di codebase, bukan asumsi. (Prinsip
    anti-rasionalisasi, metodologi trailofbits-skills, fase B.)
```

---

## Yang TIDAK diusulkan (sudah tercakup memadai)

Pola-pola berikut sudah ada di skill (atau tercakup oleh pola di atas)
dengan rumusan yang cukup — TIDAK perlu blok baru, hanya dicatat
sebagai konfirmasi dari korpus:

- **Divide-before-multiply + arah pembulatan** (Mercury 3.2.3, 3.2.4,
  3.2.5, 3.4.2, 3.4.5) — sudah di skill `fixed-point-rounding` +
  sc-audit Fase 4 Aritmetika + bounty-hunter Fase 2 ranking #2
  (fase J juga mencatat "Rounding/presisi" sebagai sudah tercakup).
  Yang BARU hanya bagian ill-conditioned — itu masuk sebagai C-05.
- **Allocated reserves over-reported + outstanding reserves dalam
  yield** (Mercury 3.3.1, 3.3.2) — varian dari C-01 (akuntansi satu
  sisi); tercakup oleh blok C-01, tidak perlu butir terpisah.
- **Reuse kolateral via swapping jumlah nol** (Mercury 3.6.2,
  Informational) — pola "amount 0" yang sama dengan DVD #2 Naive
  Receiver / #3 Truster (sudah di skill); tidak perlu butir baru.
- **Reentrancy / access control dasar / `tx.origin` / delegatecall tak
  terbatas / inflasi share** — sudah dicatat di fase J sebagai tidak
  diusulkan; korpus tidak menambah varian baru untuk pola-pola itu.

## Catatan verifikasi (untuk main chat)

- Dokumen ini PROPOSAL — tidak ada file skill yang diubah. Periksa
  sebelum menerapkan: (1) setiap sumber pola ada di korpus/metodologi
  yang dirujuk (C4/Cantina 3 laporan final + 3 file metodologi fase B,
  semua dibaca penuh); (2) setiap blok teks dalam Bahasa Indonesia,
  tanpa referensi ke tool AI lain, tanpa alias model, tanpa API key,
  tanpa perintah install; (3) penempatan sesuai struktur skill yang
  ada (nomor fase dan nama butir dicek dari file skill saat ini:
  bounty-hunter 581 baris, sc-audit 500 baris, invariant-testing 203
  baris — 16 Nov 2026, setelah penerapan fase J); (4) nomor butir
  Fase 3 bounty-hunter melanjutkan dari fase J (butir 10–11 sudah
  ditambah fase J; C-02 → 12, C-04 → 13, C-06 → 14, M-04 → 15).
- Setelah diterapkan, main chat memverifikasi tiap skill yang diubah
  (hitung baris, frontmatter, grep pola terlarang) sebelum menyatakan
  skill diperbarui — sama seperti adopsi skill baru dan penerapan
  fase J.
- Pola yang TIDAK masuk proposal ini karena di luar scope korpus +
  metodologi fase B: pola dari metodologi Aderyn (taksonomi 40 high +
  50 low detektor — sebagian besar pola yang sudah dikenal, bukan
  logic) dan Building Secure Contracts (model kematangan 11 kategori
  + Uji Rekt 12 pertanyaan — kerangka penilaian, bukan pola
  kerentanan). Keduanya layak dipertimbangkan terpisah bila ada
  kebutuhan.

## Langkah berikut

1. Main chat: terapkan blok C-01..C-07, F-01, M-01..M-04 ke tiga skill
   (atau tolak sebagian dengan alasan) → verifikasi → catat di tracker
   + inventory.
2. Benchmark berikut: Capture The Ether (sesuai rencana misi) —
   benchmark ketiga setelah DVD 13/13 dan Ethernaut 30/30.
3. Setelah Capture The Ether: proposal integrasi berikutnya (pola
   benchmark ketiga) bila ada pola baru yang terbukti.
