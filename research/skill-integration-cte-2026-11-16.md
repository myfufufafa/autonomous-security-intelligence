# Proposal Integrasi 4 Pola Baru Capture The Ether Batch 1 ke Skill — Pass 2 fase M

**Tanggal:** 16 November 2026 (misi Skill Evolution, Pass 2 fase M)
**Status:** PROPOSAL SAJA — file skill TIDAK diubah. Main chat yang
menerapkan + memverifikasi (hitung baris, frontmatter, grep pola
terlarang) sebelum menyatakan skill diperbarui. JANGAN klaim skill
sudah diperbarui berdasarkan dokumen ini.
**Sumber:** `benchmarks/cte-baseline-1-2026-11-16.md` (394 baris) —
Capture The Ether batch 1 (Lotteries 5 + Math 4), skor **9/9**,
**18 tests passed, 0 failed** (`forge test` di `/tmp/cte-work`,
9× testInit + 9× testSolve, semua menegaskan `isComplete() ==
true`); severity 0 Critical, 2 High, 5 Medium, 2 Low; gas testSolve
total 1.893.904; semua root cause benar percobaan pertama (logika),
0 false positive; 3 kegagalan harness (test contract tanpa
`receive()`), bukan logika. Kontrak dari recreation/mirror
(RareSkills 0.8.13, raion 0.8.0 MIT, Mapping 0.4.21 asli) karena repo
resmi asli CTE hilang (404); file `test/` mirror TIDAK PERNAH dibuka
— kontaminasi nol. "Token balance" dalam brief TIDAK ADA di daftar
resmi CTE — diganti Token whale (dicatat jujur di baseline §1).
**Pola yang dicek terhadap fase J + fase K dulu:** proposal fase J
(`research/skill-integration-2026-11-16.md`, P-01..P-18, sudah
diterapkan + diverifikasi main chat) dan proposal fase K
(`research/skill-integration-corpus-2026-11-16.md`, C-01..C-07 +
F-01 + M-01..M-04, sudah diterapkan + diverifikasi main chat).
Tumpang tindih ditulis PERKUAT atau dilewati dengan alasan.
**Total pola baru di sini:** 4 pola (T-01..T-04). T = Capture The
Ether batch 1.

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
   konkret dari benchmark (diberi label "PERKUAT").
5. Setiap blok teks diusulkan persis seperti tertulis (Bahasa
   Indonesia). Main chat boleh mengedit redaksi saat menerapkan, tapi
   substansi (pola + contoh + sumber) harus tetap.

## Matriks penempatan (ringkas)

| ID | Pola | Sumber (severity) | Skill → lokasi |
|---|---|---|---|
| T-01 | Confused deputy `_transfer`: debit akun yang salah lewat `transferFrom` + allowance | CTE #7 Token whale (High) | sc-audit Fase 4 (+butir baru, setelah "Override yang tidak lengkap"); bounty-hunter Fase 2 Tier 1 (+butir baru, setelah "Access control"); invariant-testing Catatan desain (+butir, setelah "Invariant akuntansi dua sisi") |
| T-02 | Tulis slot arbitrer via overflow indeks array | CTE #9 Mapping (Medium; Critical di produksi) | sc-audit Fase 4 "Storage layout" (PERKUAT); bounty-hunter Fase 2 Tier 2 (+butir baru, setelah "Proxy upgradeable"); invariant-testing Catatan desain (+butir, setelah "Invariant di dekat titik singular") |
| T-03 | Retry-until-match / tunggu blok yang menguntungkan | CTE #5 Predict the future (Medium) | sc-audit Fase 4 "Oracle / manipulasi harga" (PERKUAT); bounty-hunter Fase 3 (+butir 16); invariant-testing Checklist (+butir, setelah butir ketergantungan waktu) |
| T-04 | Penalti = seluruh sisa saldo + kolusi dua-peran | CTE #8 Retirement fund (Medium) | sc-audit Fase 4 (+butir baru, setelah "Gate yang mempercayai nilai turunan yang sudah rusak"); bounty-hunter Fase 3 (+butir 17); invariant-testing Catatan desain (+butir, setelah "Invariant kepemilikan per-pool") |

---

## T-01 — Confused deputy `_transfer`: debit akun yang salah lewat `transferFrom` + allowance

**Sumber:** CTE #7 Token whale (500 poin, High, gas 1.209.922,
~6 menit). `TokenWhale` (0.8.13): `balanceOf[player] = 1000`;
`isComplete`: `balanceOf[player] >= 1000000`. `_transfer(to, value)`
melakukan `unchecked { balanceOf[msg.sender] -= value;
balanceOf[to] += value; }`. `transferFrom(from, to, value)`
memeriksa `balanceOf[from] >= value` dan
`allowance[from][msg.sender] >= value`, lalu `allowance -= value`
dan memanggil `_transfer(to, value)`.
**Root cause:** CONFUSED DEPUTY — `_transfer` mendebit
`msg.sender`, BUKAN `from`. `transferFrom(player, player, v)` lolos
semua cek (saldo player >= v, allowance >= v), tapi yang didebit
adalah CALLER (saldo 0 → underflow `unchecked` → astronomis) dan
yang dikredit adalah player (+v). Dengan v = saldo player saat itu,
saldo player BERLIPAT GANDA tiap iterasi: 1.000 → 2.000 → … →
1.024.000 dalam 10 iterasi (tiap iterasi butuh approve ulang dari
player sebesar saldo saat itu).
**Bedanya dengan yang sudah ada:** fase J menyebut `transferFrom`
hanya di dua tempat, dan keduanya soal lain: P-09 (return value
`transferFrom` yang gagal diam-diam) dan P-13 (override ERC20
selektif — `transferFrom()` tidak di-override sehingga timelock
dilewati). TIDAK ADA pola soal fungsi transfer internal yang
mendebit akun yang salah. Di DVD (13/13) maupun Ethernaut (30/30)
underflow selalu soal saldo sendiri (Token #5) atau mint (Rewarder
#5), bukan debit akun yang salah lewat `transferFrom`. Pola ini
BARU — bukan PERKUAT.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Override yang
tidak lengkap":**

```text
- **Confused deputy di fungsi transfer internal.** Fungsi internal
  (`_transfer`, `_mint`, `_burn`, `_move`) yang memakai `msg.sender`
  padahal dipanggil dari `transferFrom`/`transfer` dengan parameter
  `from` yang berbeda akan mendebit/mengkredit akun yang SALAH.
  Untuk SETIAP fungsi internal yang memindahkan nilai, tanya: akun
  mana yang didebit — `msg.sender`, `from`, atau `to`? Dan apakah
  pemanggil fungsi ini selalu `from` itu sendiri? Bila `allowance`
  menjadi satu-satunya izin, ingat: allowance sekecil apa pun +
  debit yang salah = pencetakan saldo tanpa batas (saldo target
  berlipat ganda tiap iterasi). (CTE #7 Token whale: `_transfer`
  mendebit `msg.sender`, bukan `from` → `transferFrom(player,
  player, v)` mengkredit player +v sambil mendebit caller yang
  saldonya 0 → underflow `unchecked` → saldo caller astronomis;
  saldo player 1.000 → 1.024.000 dalam 10 iterasi.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 1, butir baru (setelah
"Access control"):**

```text
- Confused deputy di transfer internal — fungsi `_transfer`/`_move` yang mendebit `msg.sender` padahal dipanggil dari `transferFrom(from, ...)`; allowance kecil + debit salah = saldo tercetak dari ketiadaan (CTE #7 Token whale: 1.000 → 1.024.000 dalam 10 iterasi).
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant akuntansi dua sisi"):**

```text
- **Invariant konservasi transfer: debit(`from`) == kredit(`to`).**
  Untuk `transferFrom(from, to, v)`, tulis invariant "saldo `from`
  berkurang tepat v, saldo `to` bertambah tepat v, jumlah saldo
  semua akun tetap" — dan uji dengan handler yang memanggil
  `transferFrom` dari akun KETIGA (bukan `from`), dengan allowance
  kecil. Bila jumlah saldo bertambah, ada confused deputy.
  (CTE #7 Token whale.)
```

---

## T-02 — Tulis slot arbitrer via overflow indeks array

**Sumber:** CTE #9 Mapping (750 poin, Medium, gas 75.267, ~5 menit).
`MappingChallenge` (0.4.21 ASLI): `bool public isComplete` (slot
0), `uint256[] map` (slot 1, data di `keccak256(1)`). `set(key,
value)`: bila `map.length <= key`, `map.length = key + 1`, lalu
`map[key] = value`. TIDAK ADA fungsi yang pernah menyetel
`isComplete = true`.
**Root cause:** penulisan array dinamis memakai aritmetika slot:
`map[key]` berada di slot `keccak256(1) + key` (mod 2^256). Dengan
`key = 2^256 − keccak256(1)`, tulisan mendarat di slot 0 — tepat di
`isComplete`. `map.length = key + 1` hanya menulis slot 1 (panjang
array), tidak menghalangi. Satu panggilan `set` menulis variabel
state yang tidak pernah dimaksudkan untuk ditulis lewat fungsi itu.
**Bedanya dengan yang sudah ada:** P-16 fase J (underflow panjang
array 0.5 + delegatecall menimpa pointer library, Ethernaut #25
AlienCodex) memakai `retract()` underflow panjang array lalu
`revise()` menulis slot 0 — mekanismenya MIRIP (tulis slot 0 lewat
array), tapi jalurnya BERBEDA: di sini panjang array diperbesar
secara LEGAL (`map.length = key + 1`) dan indeks yang dipilih
membuat `keccak256(slot) + key` membungkus ke 0. P-06 fase J
(storage packing + `private` terbaca) hanya soal MEMBACA slot. Yang
BARU di sini: MENULIS slot arbitrer lewat aritmetika indeks yang
legal. Karena itu usulan di bawah ditulis sebagai PERKUAT pada
butir "Storage layout" (sc-audit) + butir baru di dua skill lain.
**Severity di produksi:** sebagai kelas kerentanan — penulisan
storage arbitrer lewat indeks array — ini Critical: satu panggilan
fungsi bisa menimpa owner, paused, atau saldo siapa pun bila
layout-nya diketahui.

**USULAN TEKS — sc-audit, Fase 4, butir "Storage layout — ukur,
jangan tebak" (PERKUAT — tambah paragraf setelah kalimat
Keccak-256):**

```text
  PERKUAT — bukan hanya MEMBACA slot, tapi MENULIS slot arbitrer
  lewat aritmetika indeks. Fungsi yang menulis array dinamis dengan
  indeks dari pengguna (`map[key] = value`) menulis slot
  `keccak256(slot) + key` (mod 2^256): bila panjang array bisa
  diperbesar secara legal (`map.length = key + 1`) dan `key` dipilih
  penyerang, tulisan bisa mendarat di slot mana pun — termasuk slot
  0 (`owner`, `isComplete`, `paused`). Hitung `keccak256(slot) +
  key` untuk SEMUA fungsi yang menulis array dengan indeks pengguna,
  dan tanyakan: indeks berapa yang menulis slot 0/1/2? (CTE #9
  Mapping: `key = 2^256 − keccak256(1)` → `set(key, 1)` menulis
  `isComplete` di slot 0. Beda dengan Ethernaut #25 AlienCodex:
  di sana panjang array di-underflow dulu; di sini panjang
  diperbesar secara legal.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 2, butir baru (setelah
"Proxy upgradeable"):**

```text
- Tulis slot arbitrer via indeks array — fungsi `set(key, value)` pada array dinamis menulis `keccak256(slot) + key`; indeks yang dipilih penyerang bisa mendarat di slot 0 (owner/paused). Hitung indeks yang menulis slot sensitif untuk setiap fungsi tulis-array. (CTE #9 Mapping.)
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant di dekat titik singular"):**

```text
- **Invariant batas tulis array: `arr[i]` hanya boleh menyentuh
  slot yang dimaksud.** Untuk fungsi yang menulis array dinamis
  dengan indeks dari pengguna, tulis invariant "tidak ada slot di
  luar `keccak256(slot) + [0, length)` yang berubah" dan fuzz
  dengan handler yang memasukkan indeks raksasa (termasuk
  `2^256 − keccak256(slot)`) — indeks yang membungkus ke slot 0
  adalah penulisan storage arbitrer. (CTE #9 Mapping.)
```

---

## T-03 — Retry-until-match / tunggu blok yang menguntungkan

**Sumber:** CTE #5 Predict the future (500 poin, Medium, gas
209.470, ~6 menit). `PredictTheFuture` (0.8.13): `lockInGuess(n)`
(1 ether, `settlementBlockNumber = block.number + 1`); `settle()`
(hanya guesser, `block.number > settlementBlockNumber`) menghitung
jawaban `= keccak256(blockhash(block.number-1), block.timestamp) %
10`; `guesser = address(0)` DULU, baru bila tebakan benar kirim
2 ether.
**Root cause:** (a) jawaban settle dihitung dari data blok saat
settle — bisa dihitung SEBELUM memanggil settle di blok yang sama;
(b) tebakan yang salah TIDAK menghukum: `guesser` di-reset sehingga
bisa lock lagi, dan tebakan yang sudah terkunci bisa "ditunggu" —
cukup tunggu blok yang jawabannya == tebakan, baru settle. PoC:
attacker lock tebakan 0; loop: `vm.roll(block.number + 1)`, hitung
jawaban blok saat itu; bila == 0, panggil `settle()` → 2 ether.
Rata-rata ~10 blok tunggu (peluang 1/10 per blok).
**Bedanya dengan yang sudah ada:** P-17 fase J (randomness blockhash
+ constructor typo + underflow pra-0.8, Ethernaut #3 CoinFlip)
mencakup "randomness dari `blockhash`/`block.timestamp` dapat
diprediksi" — tapi itu soal MEMPREDIKSI jawaban untuk satu blok
tertentu. Yang BARU di sini adalah MEMILIH WAKTU eksekusi:
penyerang tidak perlu memprediksi apa pun — ia menghitung jawaban
yang sudah bisa dihitung, lalu mengeksekusi hanya di blok yang
jawabannya menguntungkan. Dua unsur yang membuatnya menang: jawaban
bisa dihitung sebelum eksekusi + tebakan salah tidak dihukum
(retry gratis). Karena itu usulan di bawah ditulis sebagai PERKUAT
pada butir "Oracle / manipulasi harga" (sc-audit) + butir baru di
dua skill lain.

**USULAN TEKS — sc-audit, Fase 4, butir "Oracle / manipulasi harga"
(PERKUAT — tambah paragraf setelah kalimat randomness CoinFlip):**

```text
  PERKUAT — bukan hanya memprediksi jawaban untuk satu blok, tapi
  MEMILIH WAKTU eksekusi. Bila jawaban bisa dihitung sebelum
  eksekusi DAN tebakan yang salah tidak dihukum (bisa lock lagi,
  bisa menunggu), penyerang cukup mengeksekusi di blok yang
  jawabannya menguntungkan — retry-until-match. Tanyakan untuk
  setiap lotre/prediksi dengan settlement tertunda: (a) bisakah
  jawaban dihitung sebelum settle? (b) apa biaya tebakan yang
  salah? (c) bisakah settle ditunda sampai kondisi menang?
  (CTE #5 Predict the future: jawaban settle dihitung dari
  blockhash + timestamp blok settle → hitung dulu, tunggu blok yang
  jawabannya == tebakan (~10 blok rata-rata), baru settle.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 16 (setelah butir
15 "Jangan lewati pemeriksaan..."):**

```text
16. **Tanyakan: bisakah penyerang memilih WAKTU eksekusi?** Bila
    jawaban sebuah lotre/prediksi bisa dihitung sebelum eksekusi
    dan tebakan yang salah tidak dihukum (bisa lock lagi, bisa
    menunggu), penyerang tidak perlu memprediksi — cukup tunggu
    blok yang jawabannya menguntungkan, baru eksekusi
    (retry-until-match). Periksa biaya tebakan salah + apakah
    settle bisa ditunda. (CTE #5 Predict the future.)
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru
(setelah "Bila protokol bergantung waktu
(`timestamp`/`block.number`)..."):**

```text
- [ ] Bila fungsi settle bisa dipanggil kapan saja setelah lock,
  handler sudah menguji penundaan settle sampai kondisi
  menguntungkan (retry-until-match) — bukan hanya settle segera
  (CTE #5 Predict the future).
```

---

## T-04 — Penalti = seluruh sisa saldo + kolusi dua-peran

**Sumber:** CTE #8 Retirement fund (500 poin, Medium, gas 79.890,
~4 menit). `RetirementFund` (0.8.13): constructor(player) menyimpan
1 ether, `owner = msg.sender` (deployer), `beneficiary = player`,
`expiration = +520 minggu`. `withdraw()` (hanya owner): bila lebih
awal, kirim 90% saldo ke owner (penalti 10% tertinggal).
`collectPenalty()` (hanya beneficiary): `withdrawn = startBalance -
balance` (`unchecked`), `require(withdrawn > 0)`, lalu kirim
SELURUH sisa saldo ke beneficiary.
**Root cause:** "penalti" bukan 10% — `collectPenalty` mengirim
seluruh sisa saldo (10%) ke beneficiary. Owner + beneficiary yang
berkolusi menguras dana penuh: owner tarik 90% lebih awal,
beneficiary klaim 10% sisanya. Tidak ada pemisahan antara "dana
penalti" dan "dana yang bisa diklaim beneficiary" — dan tidak ada
yang mencegah owner dan beneficiary adalah pihak yang sama /
berkolusi. `withdrawn` dihitung benar, `require` benar — yang salah
adalah SEMANTIK klaimnya.
**Bedanya dengan yang sudah ada:** yang terdekat adalah C-01 fase K
(akuntansi satu sisi — aset dikredit, kewajiban diabaikan, Monetrix
M-01). Di C-01 yang salah adalah AKUNTANSINYA (field borrow dibuang
saat decode). Di sini akuntansinya BENAR — yang salah adalah
SEMANTIK klaim: "penalti" yang seharusnya 10% dibayar 100% dari
sisa saldo. Ditambah unsur kolusi dua-peran, yang tidak ada di pola
mana pun sebelumnya (fase J + fase K tidak punya pola kolusi
dua-peran). Pola ini BARU — bukan PERKUAT.

**USULAN TEKS — sc-audit, Fase 4, butir baru setelah "Gate yang
mempercayai nilai turunan yang sudah rusak":**

```text
- **Semantik klaim vs nama fungsi + kolusi dua-peran.** Fungsi
  yang membayar "penalti" / "fee" / "bagian" / "klaim" bisa membayar
  SELURUH sisa saldo dengan nama yang terdengar parsial. Baca
  SEMANTIK pembayaran, bukan hanya aritmetikanya: berapa persen
  dari saldo yang keluar, dan kepada siapa? Lalu tanyakan: siapa
  yang bisa memegang DUA peran sekaligus (owner + beneficiary,
  liquidator + borrower, admin + user)? Bila dua peran bisa
  berkolusi atau dipegang pihak yang sama, "penalti" menjadi
  pencairan penuh. (CTE #8 Retirement fund: `collectPenalty`
  mengirim seluruh sisa saldo (10%) ke beneficiary; owner tarik
  90% lebih awal + beneficiary klaim sisanya = dana terkuras penuh.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 17 (setelah butir
16 dari T-03):**

```text
17. **Baca semantik pembayaran, bukan hanya aritmetikanya, dan
    tanyakan siapa yang bisa memegang dua peran.** Fungsi
    "penalti"/"fee"/"klaim" yang membayar seluruh sisa saldo
    adalah pencairan penuh dengan nama lain. Periksa: berapa persen
    saldo yang keluar, kepada siapa, dan apakah owner +
    beneficiary (atau dua peran lain) bisa berkolusi atau dipegang
    pihak yang sama. (CTE #8 Retirement fund.)
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant kepemilikan per-pool"):**

```text
- **Invariant klaim parsial: "penalti"/"fee" tidak boleh menguras
  sisa saldo.** Untuk fungsi yang mengklaim sebagian dana
  ("penalti", "fee", "bagian"), tulis invariant "saldo setelah
  klaim >= saldo sebelum klaim − batas yang dinyatakan" dan uji
  dengan handler dua-peran: satu aktor sebagai owner, aktor lain
  sebagai beneficiary — lalu gabungkan keduanya (kolusi) dan
  periksa apakah dana terkuras penuh. (CTE #8 Retirement fund.)
```

---

## Yang TIDAK diusulkan (sudah tercakup memadai)

Pola-pola berikut dari batch 1 adalah varian yang sudah dikenal —
sudah ada di skill (atau tercakup oleh pola di atas) dengan rumusan
yang cukup — TIDAK perlu blok baru, hanya dicatat sebagai konfirmasi:

- **Brute-force hash ruang kecil** (CTE #2 Guess the secret number,
  Low — hash jawaban 8-bit, brute-force 256 nilai off-chain) —
  varian generik dari P-06 fase J (tidak ada rahasia on-chain:
  `private` terbaca dari storage; hash yang dipublikasikan sama
  terbukanya dengan nilai yang dipublikasikan bila ruang preimage-nya
  kecil). Pertanyaan auditnya satu baris: "berapa besar ruang
  preimage hash ini?" — tidak perlu butir baru.
- **Randomness per-panggilan on-chain** (CTE #4 Guess the new
  number, Medium — jawaban per-panggilan dari data blok yang sama)
  — varian P-17 fase J (randomness `blockhash`/`block.timestamp`
  dapat diprediksi, Ethernaut #3 CoinFlip). Sudah di sc-audit Fase 4
  "Oracle / manipulasi harga" + bounty-hunter Fase 2 Tier 1.
- **Overflow perkalian harga + asimetri checked/unchecked
  buy-vs-sell** (CTE #6 Token sale, High — overflow `unchecked` di
  `buy`: ~1,16e59 token seharga 0,416 ether, jual 1 token → 1 ether)
  — overflow `unchecked` sudah di sc-audit Fase 4 "Aritmetika /
  presisi" (blok `unchecked`) + P-17 fase J (underflow pra-0.8).
  Nuansa asimetri (satu jalur overflow, satu jalur checked — PoC
  harus memakai keduanya berurutan) sudah tersirat dalam
  pemeriksaan `unchecked` per jalur; tidak perlu butir baru.
- **Jawaban hardcoded di storage** (CTE #1 Guess the number, Low —
  jawaban 42 terbaca dari storage slot 0) — varian Ethernaut #8
  Vault, tercakup P-06 fase J (storage packing + `private` terbaca).
- **Jawaban constructor yang tetap** (CTE #3 Guess the random
  number, Medium — jawaban constructor dari blockhash + timestamp
  publik) — varian CoinFlip #3, tercakup P-17 fase J.

## Catatan verifikasi (untuk main chat)

- Dokumen ini PROPOSAL — tidak ada file skill yang diubah. Periksa
  sebelum menerapkan: (1) setiap sumber pola ada di baseline yang
  dirujuk (cte-baseline-1-2026-11-16.md §5–§10, semua dibaca penuh);
  (2) setiap blok teks dalam Bahasa Indonesia, tanpa referensi ke
  tool AI lain, tanpa alias model, tanpa API key, tanpa perintah
  install; (3) penempatan sesuai struktur skill yang ada (nomor fase
  dan nama butir dicek dari file skill saat ini: bounty-hunter 608
  baris, sc-audit 589 baris, invariant-testing 277 baris — 16 Nov
  2026, setelah penerapan fase J + fase K); (4) nomor butir Fase 3
  bounty-hunter melanjutkan dari fase K (butir 12–15 sudah ditambah
  fase K; T-03 → 16, T-04 → 17).
- Setelah diterapkan, main chat memverifikasi tiap skill yang diubah
  (hitung baris, frontmatter, grep pola terlarang) sebelum menyatakan
  skill diperbarui — sama seperti adopsi skill baru dan penerapan
  fase J + fase K.
- Pola yang TIDAK masuk proposal ini karena di luar scope batch 1:
  pola dari batch 2 CTE (Predict the block hash, Donation, Fifty
  years, Assume ownership, Token bank — 5 tantangan tersisa) akan
  masuk proposal integrasi berikutnya bila ada pola baru yang
  terbukti.

## Langkah berikut

1. Main chat: terapkan blok T-01..T-04 ke tiga skill (atau tolak
   sebagian dengan alasan) → verifikasi → catat di tracker +
   inventory.
2. Benchmark berikut: Capture The Ether batch 2 (5 tantangan
   tersisa) — benchmark keempat setelah DVD 13/13, Ethernaut 30/30,
   dan CTE batch 1 9/9.
3. Setelah batch 2: proposal integrasi berikutnya (pola benchmark
   keempat) bila ada pola baru yang terbukti.
