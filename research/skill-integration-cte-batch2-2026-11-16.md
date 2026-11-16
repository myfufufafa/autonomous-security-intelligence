# Proposal Integrasi 5 Pola Baru + 1 Item Metodologi Capture The Ether Batch 2 ke Skill — Pass 2 fase O

**Tanggal:** 17 November 2026 (misi Skill Evolution, Pass 2 fase O, dini hari)
**Status:** PROPOSAL SAJA — file skill TIDAK diubah. Main chat yang
menerapkan + memverifikasi (hitung baris, frontmatter, grep pola
terlarang) sebelum menyatakan skill diperbarui. JANGAN klaim skill
sudah diperbarui berdasarkan dokumen ini.
**Sumber:** `benchmarks/cte-baseline-2-2026-11-16.md` (296 baris) —
Capture The Ether batch 2 (5 tantangan tersisa), skor **5/5**,
**10 tests passed, 0 failed** (`forge test` di `/tmp/cte-work`,
5× testInit + 5× testSolve, semua menegaskan `isComplete() ==
true`); severity batch 2: 2 Critical, 2 High, 1 Medium, 0 Low;
gas testSolve batch 2: 678.040; **CTE SELESAI PENUH 14/14**
(batch 1: 9/9 + batch 2: 5/5; total gas 2.571.944; severity total
2 Critical, 4 High, 6 Medium, 2 Low). Semua root cause benar
percobaan pertama (logika) kecuali Donation yang butuh koreksi
analisis (kesimpulan BLOKIR tentatif terbantah bukti empiris —
lihat N-M01); 0 false positive; 2 kegagalan harness (FiftyYears
off-by-one, Donation salah baca lokasi struct), bukan logika.
Kontrak dari recreation/mirror (RareSkills, raion, MrToph 0.4.21
asli) karena repo resmi asli CTE hilang (404); file `test/` mirror
TIDAK PERNAH dibuka — kontaminasi nol.
**Pola yang dicek terhadap fase J + fase K + fase M dulu:**
proposal fase J (`research/skill-integration-2026-11-16.md`,
P-01..P-18, sudah diterapkan + diverifikasi main chat), fase K
(`research/skill-integration-corpus-2026-11-16.md`, C-01..C-07 +
F-01 + M-01..M-04, sudah diterapkan + diverifikasi main chat),
dan fase M (`research/skill-integration-cte-2026-11-16.md`,
T-01..T-04, sudah diterapkan + diverifikasi main chat).
Tumpang tindih ditulis PERKUAT atau dilewati dengan alasan.
**Total pola baru di sini:** 5 pola (N-01..N-05) + 1 item
metodologi (N-M01). N = Capture The Ether batch 2.

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
6. Keluarga bug yang sama dengan dua manifestasi (N-01 + N-02)
   memakai SATU butir keluarga di tempat yang ringkas (Tier 2
   bounty-hunter, Catatan desain invariant-testing), tapi tetap
   mendapat butir deep-dive / paragraf audit SENDIRI-SENDIRI agar
   tiap manifestasi bisa diterapkan terpisah.

## Matriks penempatan (ringkas)

| ID | Pola | Sumber (severity) | Skill → lokasi |
|---|---|---|---|
| N-01 | Pointer storage tak terinisialisasi (cabang if/else) → overwrite slot 0/1 | CTE #12 FiftyYears (High) | sc-audit Fase 4 "Storage layout" (PERKUAT, paragraf baru setelah paragraf T-02); bounty-hunter Fase 2 Tier 2 (butir baru keluarga N-01/N-02, setelah "Tulis slot arbitrer via indeks array"); bounty-hunter Fase 3 butir 18; invariant-testing Catatan desain (butir baru keluarga, setelah "Invariant batas tulis array") |
| N-02 | Struct storage tak terinisialisasi di dalam fungsi → overwrite `owner` (varian N-01) | CTE #11 Donation (Critical) | sc-audit Fase 4 "Storage layout" (PERKUAT, paragraf baru setelah paragraf N-01); bounty-hunter Fase 3 butir 19 (Tier 2 + invariant-testing memakai butir keluarga N-01) |
| N-03 | Overflow penjumlahan timestamp → bypass require | CTE #12 FiftyYears (High) | sc-audit Fase 4 "Aritmetika / presisi" (PERKUAT, sub-butir baru setelah baris underflow Token); bounty-hunter Fase 3 butir 20; invariant-testing Checklist (butir baru setelah butir retry-until-match T-03) |
| N-04 | `blockhash` blok >256 lama = 0 (time-decay ke konstanta diketahui) | CTE #10 Predict the block hash (Medium; High/Critical di produksi) | sc-audit Fase 4 "Oracle / manipulasi harga" (PERKUAT, paragraf baru setelah paragraf T-03); bounty-hunter Fase 2 Tier 1 (butir baru setelah "Manipulasi price oracle via flashloan"); invariant-testing Checklist (butir baru setelah butir N-03) |
| N-05 | Reentrancy via callback ERC223 `tokenFallback` (varian pengiriman) | CTE #14 Token bank (Critical) | sc-audit Fase 4 "Reentrancy" (PERKUAT, tambah kalimat setelah "...bukan sekadar keberadaan `nonReentrant`."); bounty-hunter Fase 2 Tier 1 (PERKUAT baris "Reentrancy (...)"); invariant-testing Catatan desain (butir baru setelah "Invariant konservasi transfer") |
| N-M01 | Uji BLOKIR empiris; kejar anomali kecil; jangan berhenti di bug pertama yang terlihat | CTE #11 Donation §4 (pelajaran metodologis) | bounty-hunter Fase 3 butir 21; sc-audit Fase 7 (PERKUAT, paragraf baru di akhir Fase 7); invariant-testing TIDAK diusulkan (metodologi, bukan pola fuzz) |

---

## N-01 — Pointer storage tak terinisialisasi (cabang if/else) → overwrite slot 0/1

**Sumber:** CTE #12 FiftyYears (High, gas 242.104, ~4 menit).
`FiftyYearsChallenge.sol` (MrToph 0.4.21 asli; raion hanya beda
format + MrToph punya anotasi `// @note` yang mengonfirmasi
mekanisme). `upsert` cabang `else` memakai `contribution` yang
hanya dideklarasikan di cabang `if`.
**Root cause:** di Solidity 0.4.x deklarasi variabel bersifat
function-scoped, jadi `contribution` (dideklarasikan di cabang
`if`) terlihat di cabang `else` tapi **tak terinisialisasi** →
menunjuk slot 0. `contribution.amount = msg.value` menulis slot 0
(`queue.length`), `contribution.unlockTimestamp = timestamp`
menulis slot 1 (`head`). `queue.push` menaikkan length DULU lalu
membaca struct — elemen yang di-push = `{amount: msg.value + 1,
unlockTimestamp: timestamp}`. Rantai penuh: Upsert A (indeks di
luar jangkauan, 1 wei, `timestamp = 2^256 − 86400`) → length=1,
head=`2^256−86400`, `queue[1] = {2, 2^256−86400}`, `queue[0] =
{1 ether, +50 tahun}` tetap utuh; Upsert B (1 wei, `timestamp =
0`) → require lolos karena overflow (lihat N-03) → head=0,
`queue[1]` ditulis ulang `{2, 0}`; `withdraw(1)` menjumlah
`queue[0]` + `queue[1]` = seluruh saldo → saldo 0.
**Bedanya dengan yang sudah ada:** ini keluarga bug BARU — bukan
PERKUAT dari pola yang sudah ada, walau penempatannya PERKUAT pada
butir "Storage layout" karena konsekuensinya sama (tulis slot
arbitrer). P-16 fase J (underflow panjang array 0.5, Ethernaut #25
AlienCodex: `retract()` underflow length lalu `revise()` menulis
slot 0) memakai pemicu BERBEDA: pengurangan length secara eksplisit
(`length--` pada array kosong). Di N-01 TIDAK ADA pengurangan
length dan TIDAK ADA underflow — pointer-nya sendiri yang default
ke slot 0 karena tidak diinisialisasi. P-06 fase J (storage packing
+ `private` terbaca) hanya soal MEMBACA slot, bukan MENULIS.
T-02 fase M (tulis slot arbitrer via overflow indeks array, CTE #9
Mapping) memakai jalur BERBEDA: panjang array diperbesar secara
LEGAL lalu indeks yang dipilih membungkus `keccak256(slot) + key`
ke slot 0. Di N-01 tidak ada indeks array sama sekali — penulisan
field struct langsung mendarat di slot 0/1. Tiga pemicu berbeda
(underflow length / aritmetika indeks / pointer tak terinisialisasi),
satu konsekuensi (tulis slot arbitrer). Di Solidity modern (0.5.0+)
pola ini sudah tidak bisa dikompilasi — tapi tetap relevan saat
mengaudit kontrak lama / fork 0.4.x yang masih beredar.

**USULAN TEKS — sc-audit, Fase 4, butir "Storage layout — ukur,
jangan tebak" (PERKUAT — paragraf baru setelah paragraf T-02
tentang tulis slot via indeks array):**

```text
  PERKUAT — bukan hanya MENULIS slot lewat indeks array, tapi
  lewat POINTER STORAGE TAK TERINISIALISASI. Di Solidity 0.4.x,
  variabel lokal bertipe struct/array TANPA penentu lokasi
  (`memory`/`storage`) default ke STORAGE dan bila tak
  diinisialisasi menunjuk slot 0. Deklarasi bersifat
  function-scoped: variabel yang dideklarasikan di cabang `if`
  tetap terlihat di cabang `else` — tapi nilainya tidak pernah
  di-set, sehingga penulisan field-nya menimpa slot 0 dan slot 1
  (panjang array, `head`, atau variabel state apa pun yang tinggal
  di sana). Untuk SETIAP deklarasi struct/array lokal di kontrak
  0.4.x, tanya: ada penentu lokasinya? Bila tidak, ke slot mana ia
  menunjuk — dan field apa yang ditulis ke slot itu? (CTE #12
  FiftyYears: `contribution` dideklarasikan di cabang `if`,
  dipakai di cabang `else` tanpa inisialisasi → `amount` menimpa
  slot 0 `queue.length`, `unlockTimestamp` menimpa slot 1 `head`.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 2, butir baru
(setelah "Tulis slot arbitrer via indeks array"; butir keluarga
N-01 + N-02):**

```text
- Pointer storage tak terinisialisasi (Solidity 0.4.x) — variabel struct/array lokal tanpa penentu `memory`/`storage` default ke storage dan menunjuk slot 0; penulisan field-nya menimpa slot 0/1 (length, head, owner). Periksa setiap deklarasi lokal di kontrak 0.4.x: ada penentu lokasinya? (CTE #12 FiftyYears; CTE #11 Donation: struct lokal di dalam fungsi menimpa `owner` di slot 1.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 18 (setelah
butir 17 dari T-04):**

```text
18. **Tanyakan: ada pointer storage tak terinisialisasi?** Di
    Solidity 0.4.x, variabel lokal struct/array tanpa penentu
    lokasi default ke STORAGE dan menunjuk slot 0 bila tak
    diinisialisasi — termasuk variabel yang dideklarasikan di satu
    cabang `if`/`else` lalu dipakai di cabang lain (function-scoped).
    Lacak: variabel lokal apa yang ditulis sebelum di-assign, dan
    slot mana yang tertimpa oleh tiap field-nya? (CTE #12
    FiftyYears: `contribution` dari cabang `if` dipakai di `else`
    → `amount` timpa slot 0, `unlockTimestamp` timpa slot 1.)
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant batas tulis array"; butir keluarga N-01 +
N-02):**

```text
- **Invariant slot 0/1: hanya fungsi yang dimaksud yang boleh
  menulisnya.** Untuk kontrak 0.4.x, tulis invariant "slot 0
  (panjang array / variabel pertama) dan slot 1 hanya berubah
  lewat fungsi yang dimaksud menulisnya" dan uji dengan handler
  yang memanggil tiap fungsi dengan argumen yang memicu SEMUA
  cabang (`if`/`else`) — cabang yang tidak terpicu di unit test
  adalah tempat pointer tak terinisialisasi bersembunyi. Bila
  `owner` atau panjang array berubah setelah panggilan yang
  seharusnya hanya membaca/menulis elemen, ada pointer storage
  tak terinisialisasi. (CTE #12 FiftyYears, #11 Donation.)
```

---

## N-02 — Struct storage tak terinisialisasi di dalam fungsi → overwrite `owner` (varian N-01)

**Sumber:** CTE #11 Donation (Critical, gas 133.115, ~6 menit).
`DonationChallenge.sol` (MrToph 0.4.21 asli; identik dengan raion,
diff kosong). `donate(etherAmount)`: `scale = 10**18 * 1 ether =
10^36`, `require(msg.value == etherAmount / scale)`; `withdraw()`
owner-only; `isComplete` = saldo 0.
**Root cause:** `Donation donation;` di dalam `donate()` **tanpa**
penentu lokasi `memory`/`storage`. Di Solidity 0.4.x, variabel
lokal bertipe struct **default ke STORAGE** dan bila tak
diinisialisasi menunjuk **slot 0**. Layout: slot 0 =
`donations.length`, slot 1 = `owner`. Maka:
- `donation.timestamp = now` → slot 0 = `now` (length!)
- `donation.etherAmount = etherAmount` → slot 1 = `etherAmount`
  (**OWNER!**)
- `donations.push(donation)` → length `now+1`, elemen di indeks
  `now`.

Penyerang memanggil `donate(uint160(alamatPenyerang))` dan
**menjadi owner**, lalu `withdraw()` menguras seluruh saldo.
Require `msg.value` terpenuhi dengan nilai kecil: alamat 160-bit /
10^36 ≤ ~1,46e12 wei.
**Bedanya dengan yang sudah ada:** keluarga yang SAMA dengan N-01
(pointer storage tak terinisialisasi) — tapi manifestasi BERBEDA:
bukan variabel cabang if/else, melainkan struct lokal di dalam
fungsi; dan dampaknya langsung ke `owner` di slot 1 (takeover tanpa
autentikasi + drain penuh, Critical). Bukan PERKUAT dari P-16
(tidak ada underflow length) maupun T-02 (tidak ada aritmetika
indeks). Karena satu keluarga, penempatan ringkas (Tier 2
bounty-hunter + Catatan desain invariant-testing) memakai butir
keluarga N-01 di atas — tetapi pola ini tetap mendapat paragraf
audit (sc-audit) dan butir deep-dive (bounty-hunter Fase 3)
SENDIRI, karena pertanyaan auditnya berbeda: bukan "variabel
cabang mana yang dipakai di cabang lain", melainkan "struct lokal
di fungsi ini menunjuk ke mana, dan field ke-N menimpa slot
ke-(N−1) yang mana".

**USULAN TEKS — sc-audit, Fase 4, butir "Storage layout — ukur,
jangan tebak" (PERKUAT — paragraf baru setelah paragraf N-01):**

```text
  Varian dari pola di atas: struct lokal DI DALAM FUNGSI tanpa
  penentu lokasi. `Donation donation;` di dalam `donate()` —
  tanpa `memory`/`storage` — adalah pointer storage tak
  terinisialisasi yang menunjuk slot 0: penulisan field pertama
  menimpa variabel state di slot 0, penulisan field kedua menimpa
  slot 1. Bila slot 1 adalah `owner`, satu panggilan fungsi biasa
  mengubah pemilik kontrak. Periksa juga URUTAN field struct vs
  URUTAN slot state: field ke-N menimpa slot ke-(N−1) — hitung
  untuk tiap struct lokal tanpa penentu lokasi. (CTE #11
  Donation: `donation.timestamp = now` → slot 0 `length = now`;
  `donation.etherAmount = etherAmount` → slot 1 `owner =
  etherAmount` → `donate(uint160(penyerang))` lalu `withdraw()`.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 19 (setelah
butir 18 dari N-01):**

```text
19. **Tanyakan: struct lokal di dalam fungsi — ke mana ia
    menunjuk?** Di Solidity 0.4.x, `Struct s;` tanpa penentu
    lokasi di dalam fungsi adalah pointer storage tak
    terinisialisasi (slot 0), BUKAN memory. Petakan field struct
    ke slot state satu per satu: field ke-N menimpa slot ke-(N−1)
    — bila salah satu slot itu `owner`, satu panggilan mengubah
    pemilik. Jangan terkecoh bug lain yang lebih mencolok di fungsi
    yang sama (di Donation, bug divisi integer itu nyata tapi
    inert — bug sesungguhnya satu baris di atasnya). (CTE #11
    Donation.)
```

**Penempatan lain:** Tier 2 bounty-hunter + Catatan desain
invariant-testing memakai butir keluarga N-01 di atas (tidak ada
butir terpisah untuk N-02 di kedua tempat itu — sudah tercakup
dalam teks keluarga yang menyebut Donation secara eksplisit).

---

## N-03 — Overflow penjumlahan timestamp → bypass require

**Sumber:** CTE #12 FiftyYears (High, gas 242.104 — PoC yang sama
dengan N-01; dua bug dirantai dalam satu exploit).
**Root cause:** require di `upsert`: `timestamp >=
queue[queue.length - 1].unlockTimestamp + 1 days`. Dengan
`unlockTimestamp = 2^256 - 86400`, penjumlahan membungkus ke 0
(aritmetika 0.4.x tanpa pengecekan) sehingga `timestamp = 0`
lolos. Rantai: Upsert A menanam `unlockTimestamp = 2^256 − 86400`
(lihat N-01); Upsert B memakai `timestamp = 0` → require lolos
karena `(2^256−86400) + 86400` membungkus ke 0 → head=0,
`queue[1]` ditulis ulang `{2, 0}`; `withdraw(1)` hanya memeriksa
`queue[1].unlockTimestamp` (0) lalu menjumlah seluruh saldo.
**Bedanya dengan yang sudah ada:** ini PERKUAT pada cakupan
aritmetika yang sudah ada, dengan mekanisme yang belum tertulis.
Butir "Aritmetika / presisi" (sc-audit Fase 4) sudah mencakup blok
`unchecked` + underflow pra-0.8 (Ethernaut #5 Token: transfer
melebihi saldo → saldo 2^256−1 — UNDERFLOW pada pengurangan
saldo). N-03 adalah OVERFLOW pada PENJUMLAHAN — dan bukan pada
saldo, melainkan DI DALAM EKSPRESI REQUIRE/GUARD itu sendiri:
guard mengalahkan dirinya sendiri. C-04 fase K (boundary
off-by-one + urutan eksekusi, EigenLayer `>` vs `>=`) soal
kesetaraan di perbandingan, bukan pembungkusan hasil aritmetika di
dalam nilai yang dibandingkan. M-01 fase K (kasus batas manual ala
Halmos) soal menguji nilai batas — N-03 adalah KASUS BATAS yang
harus diuji (timestamp ekstrem + durasi), tapi pola kerentanannya
sendiri (guard yang membungkus) belum tertulis di mana pun.
**Catatan harness (bukan pola, tapi ikut tertulis di teks N-03):**
hitung batas overflow eksplisit sebagai `2^256 − N`, bukan
`MAX − N` — `MAX − 86400 = 2^256 − 86401`, bukan `2^256 − 86400`
(off-by-one di PoC pertama, dibuktikan probe `vm.load`).

**USULAN TEKS — sc-audit, Fase 4, butir "Aritmetika / presisi"
(PERKUAT — sub-butir baru setelah baris "Underflow pra-0.8 (tanpa
checked arithmetic bawaan): transfer melebihi saldo → saldo
2^256−1. (Ethernaut #5 Token.)"):**

```text
  - **Overflow di DALAM ekspresi require/guard.** Penjumlahan
    yang membungkus bisa membuat guard meloloskan nilai yang
    seharusnya ditolak: `timestamp >= unlockTimestamp + 1 days`
    lolos dengan `timestamp = 0` bila `unlockTimestamp + 1 days`
    membungkus ke 0 (aritmetika 0.4.x tanpa pengecekan). Untuk
    SETIAP `require` yang membandingkan hasil penjumlahan /
    pengurangan, tanya: bisakah operan dibuat sedemikian rupa
    sehingga hasilnya membungkus melewati nilai yang dibandingkan?
    Hitung batas overflow eksplisit sebagai `2^256 − N`, bukan
    `MAX − N` (selisih satu: `MAX − 86400 = 2^256 − 86401`, bukan
    `2^256 − 86400`). (CTE #12 FiftyYears: `unlockTimestamp =
    2^256 − 86400` → `+ 86400` membungkus ke 0 → `timestamp = 0`
    lolos require timelock.)
```

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 20 (setelah
butir 19 dari N-02):**

```text
20. **Tanyakan: bisakah penjumlahan di dalam `require` membungkus?**
    Guard yang membandingkan hasil aritmetika bisa dikalahkan oleh
    overflow operannya sendiri — `timestamp >= unlock + 1 days`
    lolos dengan `timestamp = 0` bila `unlock + 1 days` membungkus
    ke 0. Untuk tiap require dengan penjumlahan/pengurangan, hitung
    nilai operan yang membuat hasilnya membungkus (pakai `2^256 − N`
    eksplisit, bukan `MAX − N`). (CTE #12 FiftyYears.)
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru
(setelah butir retry-until-match T-03: "Bila fungsi settle bisa
dipanggil kapan saja setelah lock, ..."):**

```text
- [ ] Bila `require` membandingkan hasil penjumlahan/pengurangan
  (mis. `timestamp >= unlock + durasi`), handler sudah menguji
  operan ekstrem (`2^256 − N`) + `max_time_delay` maksimum —
  penjumlahan di dalam guard bisa membungkus ke 0 dan meloloskan
  nilai yang seharusnya ditolak (CTE #12 FiftyYears).
```

---

## N-04 — `blockhash` blok >256 lama = 0 (time-decay ke konstanta diketahui)

**Sumber:** CTE #10 Predict the block hash (Medium, gas 135.991,
~2 menit). `PredictTheBlockHashChallenge.sol` (raion 0.8.0).
`lockInGuess` menyimpan `settlementBlockNumber = block.number +
1`; `settle()` memakai `blockhash(settlementBlockNumber)`.
**Root cause:** `blockhash()` mengembalikan `0x0` untuk blok yang
sudah lebih dari 256 blok lama. Jadi tebak `0x0`, tunggu 257+ blok,
lalu `settle()` — jawaban selalu 0, menang 2 ether. PoC: kunci
tebakan `0x0`, `vm.roll(block.number + 300)`, `settle()`. Lolos
percobaan pertama.
**Severity: Medium** di kontrak game ini (taruhan terbatas 2 ether,
butuh menunggu 257 blok). Tapi primitifnya serius: randomness apa
pun yang bergantung pada `blockhash` blok lama adalah
deterministik-nol. Di produksi (lotere, RNG on-chain) kelas ini
High/Critical — teks usulan mencatat kedua sisi ini.
**Bedanya dengan yang sudah ada:** mekanisme BARU — bukan PERKUAT
dari P-17 maupun T-03, walau penempatannya PERKUAT pada butir
"Oracle / manipulasi harga" karena ketiganya soal nilai yang
bergantung pada blok. P-17 fase J (randomness blockhash +
constructor typo + underflow pra-0.8, Ethernaut #3 CoinFlip)
mencakup "randomness dari `blockhash`/`block.timestamp` dapat
diprediksi" — tapi itu soal MEMPREDIKSI jawaban untuk satu blok
tertentu. T-03 fase M (retry-until-match, CTE #5 Predict the
future) soal MEMILIH WAKTU eksekusi: jawaban bisa dihitung sebelum
settle + tebakan salah tidak dihukum → tunggu blok yang jawabannya
menguntungkan. N-04 bukan keduanya: TIDAK ADA prediksi (jawabannya
bukan dihitung — ia SUDAH DIKETAHUI: 0) dan TIDAK ADA retry (tidak
ada tebakan salah — sekali tunggu, sekali settle, selalu menang).
Yang baru: nilai yang tadinya acak MENJADI NOL setelah jendela 256
blok — time-decay ke konstanta yang diketahui.

**USULAN TEKS — sc-audit, Fase 4, butir "Oracle / manipulasi harga"
(PERKUAT — paragraf baru setelah paragraf T-03 tentang
retry-until-match):**

```text
  PERKUAT — bukan hanya memprediksi jawaban atau memilih waktu
  eksekusi, tapi menunggu nilai MENJADI KONSTANTA YANG DIKETAHUI.
  `blockhash(n)` mengembalikan `0x0` untuk blok yang sudah lebih
  dari 256 blok lama: randomness yang bergantung pada blockhash
  blok lama adalah deterministik-nol. Tebak `0x0`, tunggu 257+
  blok, lalu settle — jawaban selalu 0, tanpa prediksi dan tanpa
  retry. Tanyakan untuk setiap pemakaian `blockhash`: blok mana
  yang dibaca, dan bisakah eksekusi ditunda sampai blok itu
  melewati jendela 256 blok? (CTE #10 Predict the block hash:
  `settlementBlockNumber = block.number + 1`, tebak `0x0`,
  `vm.roll` +300 blok, `settle()` → menang 2 ether. Di game ini
  Medium; di lotere/RNG produksi kelas ini High/Critical.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 1, butir baru
(setelah butir "Manipulasi price oracle via flashloan"):**

```text
- Time-decay blockhash ke nol — `blockhash(n)` = `0x0` untuk blok >256 lama; randomness dari blockhash blok lama adalah deterministik-nol. Tebak 0, tunggu 257+ blok, settle. (CTE #10 Predict the block hash.)
```

**USULAN TEKS — invariant-testing, "Checklist", butir baru
(setelah butir N-03):**

```text
- [ ] Bila randomness memakai `blockhash`, handler sudah menguji
  settle setelah 257+ blok (`max_block_delay` besar) — `blockhash`
  blok yang sudah >256 lama adalah `0x0`, bukan acak (CTE #10
  Predict the block hash).
```

---

## N-05 — Reentrancy via callback ERC223 `tokenFallback` (varian pengiriman)

**Sumber:** CTE #14 Token bank (Critical, gas 88.168, ~2 menit).
`TokenBankChallenge.sol` (MrToph 0.4.21 asli; raion hanya beda
format). `SimpleERC223Token` + `TokenBankChallenge`; `withdraw`
memanggil `token.transfer` **SEBELUM** `balanceOf[msg.sender] -=
amount`; callback ERC223 `tokenFallback` memungkinkan reentrancy.
**Root cause:** checks-effects-interactions dilanggar — transfer
token (sebelum pengurangan saldo) memicu callback `tokenFallback`
di kontrak penyerang, yang masuk lagi ke `withdraw`. **Harus
memakai 0.4.21 asli**: di Solidity 0.8, pengurangan di luar akan
revert karena underflow (aritmetika terperiksa) dan exploit gagal.
PoC: attacker dengan `tokenFallback` yang masuk lagi ke
`withdraw(500000e18)` sekali (guard flag) → saldo token bank 0 →
pengurangan di luar underflow diam-diam (0.4.21) → tanpa revert →
`isComplete` true.
**Bedanya dengan yang sudah ada:** kelasnya dikenal (reentrancy —
Ethernaut #10, sudah di sc-audit Fase 4 butir "Reentrancy" dan di
bounty-hunter Fase 2 Tier 1 sebagai satu baris yang sudah menyebut
"callback ERC-777"), tapi mekanisme PENGIRIMAN baru: callback
ERC223 `tokenFallback` sebagai vektor reentrancy (bukan
`receive()`/`fallback()` Ether biasa, bukan hook ERC777). Karena
itu usulan di bawah ditulis sebagai PERKUAT pada kedua butir
reentrancy yang sudah ada + satu butir invariant baru. Dua nuansa
yang ikut dicatat dalam teks: (a) transfer TOKEN (bukan ETH) yang
terjadi sebelum pengurangan saldo adalah pemicu yang harus dicari;
(b) ketergantungan versi compiler — di 0.8 exploit yang sama gagal
karena underflow luar revert, di 0.4.x lolos diam-diam.

**USULAN TEKS — sc-audit, Fase 4, butir "Reentrancy" (PERKUAT —
tambah setelah kalimat "...bukan sekadar keberadaan
`nonReentrant`."):**

```text
  PERKUAT — reentrancy tidak hanya lewat `receive()`/`fallback()`
  Ether: callback standar token adalah vektor yang sama.
  Transfer token ERC223 memicu `tokenFallback` di penerima, dan
  transfer ERC777 memicu hook — keduanya bisa masuk kembali ke
  fungsi yang mentransfer SEBELUM saldo dikurangi. Untuk SETIAP
  transfer token/ETH yang terjadi sebelum pengurangan saldo,
  tanya: callback apa yang dipicu di penerima, dan apakah callback
  itu bisa memanggil kembali fungsi ini? Periksa juga versi
  compiler: di Solidity 0.8 pengurangan di luar yang underflow
  akan revert (exploit gagal), di 0.4.x underflow diam-diam dan
  exploit lolos. (CTE #14 Token bank: `withdraw` transfer dulu
  baru kurangi saldo → `tokenFallback` masuk lagi ke `withdraw`
  → drain 500.000 token; hanya bekerja di 0.4.21 asli.)
```

**USULAN TEKS — bounty-hunter, Fase 2, Tier 1 (PERKUAT — ganti
baris "Reentrancy (cross-function, cross-contract, read-only,
callback ERC-777)" menjadi):**

```text
- Reentrancy (cross-function, cross-contract, read-only, callback ERC-777, callback ERC223 `tokenFallback`) — transfer token sebelum pengurangan saldo memicu callback penerima yang bisa masuk kembali; di 0.4.x underflow luar diam-diam, di 0.8 akan revert. (CTE #14 Token bank: drain 500.000 token.)
```

**USULAN TEKS — invariant-testing, "Catatan desain", butir baru
(setelah "Invariant konservasi transfer"):**

```text
- **Invariant urutan efek: saldo dikurangi SEBELUM transfer
  keluar.** Untuk fungsi yang mentransfer token/ETH lalu
  mengurangi saldo, tulis invariant "saldo pemanggil berkurang
  tepat v SEBELUM token/ETH keluar" dan uji dengan handler yang
  penerimanya adalah kontrak dengan callback (`tokenFallback`
  ERC223 / hook ERC777) yang memanggil kembali fungsi yang sama
  — bila saldo akhir pemanggil tidak berkurang 2× jumlah yang
  ditarik, ada reentrancy lewat callback token. (CTE #14 Token
  bank: `withdraw` transfer dulu baru kurangi saldo → reentrancy
  via `tokenFallback` → drain 500.000 token.)
```

---

## N-M01 — Uji BLOKIR empiris; kejar anomali kecil; jangan berhenti di bug pertama yang terlihat

**Sumber:** CTE #11 Donation, baseline §4 ("Kegagalan analisis #1:
Donation — BLOKIR tentatif yang TERBANTAH") — pelajaran
metodologis terpenting batch 2. Bukan pola kerentanan, melainkan
pola CARA BERPIKIR yang salah dan koreksinya.
**Kisah lengkap:** kesimpulan tentatif (salah): bug divisi integer
di `donate` bersifat inert (catatannya tak pernah dibaca);
satu-satunya ether-out adalah `withdraw()` owner-only; penyerang
bukan owner; jadi BLOKIR (SMART SKIP), skor 4/5. Bukti empiris yang
membantahnya: test analisis negatif menunjukkan `donations(0)`
mengembalikan `(0, 0)` — padahal `donate(10^36 - 1)` sudah berhasil
dan "mencatat" donasi raksasa. Kalau `Donation donation;` adalah
memory struct, elemen 0 harus berisi `(now, 10^36 - 1)`. Nilai
(0, 0) membuktikan elemen ditulis di indeks **`now`**, bukan 0 —
yang hanya mungkin bila `donation` adalah **pointer storage tak
terinisialisasi** yang menimpa slot 0 (length = `now`) sebelum push.
Dari situ terlihat konsekuensi penuhnya: slot 1 (`owner`) ikut
tertimpa dengan `etherAmount`. Kesimpulan akhir (benar): Donation
TERPECAHKAN — penyerang menjadi owner lewat satu panggilan
`donate`, lalu `withdraw()`. Skor batch 2: **5/5** (bukan 4/5).
**Tiga pelajaran (baseline §4):** (1) PoC empiris mengalahkan
analisis statis — tanpa menjalankan test negatif, kesimpulan
BLOKIR yang salah akan bertahan; (2) anomali kecil adalah petunjuk
— `(0, 0)` padahal donasi "berhasil" adalah sinyal, bukan noise,
kejar sampai ke akar; (3) jangan berhenti di bug pertama yang
terlihat — bug divisi integer itu nyata tapi inert; bug
sesungguhnya bersembunyi satu baris di atasnya (`Donation
donation;`). Baseline §6 menambahkan: "blokir harus selalu diuji,
bukan diasumsikan" — SMART SKIP tidak pernah terpicu di batch ini
justru karena BLOKIR tentatif itu diuji sebelum dicatat final.
**Bedanya dengan yang sudah ada:** ini BARU — tidak tercakup di
pola mana pun. bounty-hunter Fase 3 butir 5 (falsifikasi: "Habiskan
minimal 30 menit secara aktif mencoba MEMBUNUH hipotesismu")
berlaku SATU ARAH: membunuh hipotesis "ADA BUG". Tidak ada butir
yang mewajibkan menguji kesimpulan sebaliknya ("TIDAK ADA BUG" /
"bug ini inert" / BLOKIR). Butir 15 (anti-rasionalisasi,
metodologi trailofbits-skills) soal jangan melewati pemeriksaan
dengan alasan "tidak berlaku" tanpa bukti pencarian — dekat, tapi
soal MELEWATI CEK, bukan soal MENGUJI KEPUTUSAN NEGATIF.
sc-audit Fase 7 (verifikasi adversarial) juga satu arah: membantah
TEMUAN yang lolos triase, bukan membantah keputusan "tidak ada
temuan". Karena itu N-M01 diusulkan sebagai butir Fase 3 baru
(bounty-hunter) + paragraf PERKUAT di akhir Fase 7 (sc-audit).
**Tidak diusulkan ke invariant-testing:** ini disiplin penalaran,
bukan pola yang bisa difuzz — tidak ada invariant/checklist yang
cocok tanpa menjadi pengulangan butir Halmos/tautologi yang sudah
ada.

**USULAN TEKS — bounty-hunter, Fase 3, butir baru 21 (setelah
butir 20 dari N-03):**

```text
21. **Uji keputusan BLOKIR/SKIP secara empiris sebelum final —
    dan kejar anomali kecil sampai ke akar.** Falsifikasi (butir 5)
    berlaku dua arah: bukan hanya hipotesis "ada bug" yang harus
    dicoba dibunuh, tapi juga kesimpulan "tidak ada bug" / "bug ini
    inert". Bila analisis statis berkata BLOKIR, jalankan SATU test
    negatif sebelum mencatat final — getter yang mengembalikan 0
    padahal operasi "berhasil", saldo yang tidak berubah, atau
    nilai yang tidak masuk akal adalah PETUNJUK, bukan noise.
    Dan jangan berhenti di bug pertama yang terlihat: bug yang
    nyata tapi inert bisa menutupi bug kritis satu baris di
    atasnya. (CTE #11 Donation: kesimpulan BLOKIR tentatif
    terbantah — `donations(0)` = (0, 0) padahal donasi raksasa
    "berhasil" membuktikan struct storage tak terinisialisasi
    menimpa `owner`; bug divisi integer itu nyata tapi inert.)
```

**USULAN TEKS — sc-audit, Fase 7, paragraf baru di akhir Fase 7
(setelah "Catat tally `terverifikasi`/`terbantah` di manifest
(Fase 9) dan laporan."):**

```text
  Verifikasi adversarial berlaku DUA ARAH. Bukan hanya temuan yang
  harus dicoba dibantah — keputusan "tidak ada bug" / "bug ini
  inert" juga harus diuji sebelum final. Bila Fase 6 memutuskan
  sebuah kandidat tidak layak (atau audit menyimpulkan bersih di
  satu area), jalankan SATU test empiris negatif sebelum mencatat
  final: baca kembali nilai yang seharusnya berubah setelah operasi
  (getter, saldo, panjang array) — anomali kecil (nilai 0 padahal
  operasi "berhasil") adalah petunjuk, bukan noise. Dan jangan
  berhenti di bug pertama yang terlihat di satu fungsi: bug yang
  nyata tapi inert bisa menutupi bug kritis di baris yang sama.
  (CTE #11 Donation: BLOKIR tentatif terbantah oleh `donations(0)`
  = (0, 0).)
```

---

## Yang TIDAK diusulkan (sudah tercakup memadai atau bukan pola)

- **Assume ownership — constructor typo** (CTE #13, High —
  `AssumeOwmershipChallenge`, huruf 'n' hilang) — **BUKAN baru**:
  varian persis Ethernaut #2 Fallout. Sudah tercakup di sc-audit
  Fase 4 butir "Access control" ("Constructor yang salah eja
  (`Fal1out`, `construct0r`) adalah fungsi publik biasa yang bisa
  dipanggil siapa pun — periksa nama constructor vs nama
  kontrak."). Tidak perlu blok baru.
- **Bug divisi integer di `donate`** (CTE #11 Donation) — nyata
  TAPI INERT: catatannya (`donations`) tidak pernah dibaca oleh
  fungsi apa pun; ia hanya mekanisme agar `require(msg.value)`
  lolos murah. Pembagian sebelum perkalian / presisi sudah tercakup
  di sc-audit Fase 4 "Aritmetika / presisi". Pelajaran pentingnya
  (bug inert menutupi bug kritis) sudah ditangkap N-M01. Tidak perlu
  blok pola sendiri.
- **Off-by-one harness FiftyYears** (`MAX − 86400 = 2^256 − 86401`,
  bukan `2^256 − 86400`) — pelajaran hitung PoC, bukan pola
  kerentanan. Sudah tertanam di dalam teks N-03 ("Hitung batas
  overflow eksplisit sebagai `2^256 − N`, bukan `MAX − N`").
  Tidak perlu blok sendiri.
- **Known Issues audit BlockSec Juni 2026** (Finding #10 dan #12
  atas komponen Zcash Rust/WASM — disebut di program NoirWallet,
  BUKAN dari benchmark ini) — di luar scope proposal ini; tidak
  diusulkan.

## Catatan verifikasi (untuk main chat)

- Dokumen ini PROPOSAL — tidak ada file skill yang diubah. Periksa
  sebelum menerapkan: (1) setiap sumber pola ada di baseline yang
  dirujuk (`benchmarks/cte-baseline-2-2026-11-16.md` §1–§5, dibaca
  penuh); (2) setiap blok teks dalam Bahasa Indonesia, tanpa
  referensi ke tool AI lain, tanpa alias model, tanpa API key, tanpa
  perintah install; (3) penempatan sesuai struktur skill yang ada
  (nama butir dan nomor butir dicek dari file skill saat ini:
  bounty-hunter 624 baris — Fase 3 butir 1–17, Tier 1 baris
  "Reentrancy (...)" + "Manipulasi price oracle via flashloan",
  Tier 2 baris "Tulis slot arbitrer via indeks array" setelah
  "Proxy upgradeable"; sc-audit 638 baris — Fase 4 butir "Storage
  layout", "Aritmetika / presisi", "Oracle / manipulasi harga",
  "Reentrancy", Fase 7 akhir; invariant-testing 302 baris —
  Catatan desain butir "Invariant batas tulis array" +
  "Invariant konservasi transfer", Checklist butir ketergantungan
  waktu + butir retry-until-match T-03; semua dicek 17 Nov 2026,
  setelah penerapan fase J + K + M); (4) nomor butir Fase 3
  bounty-hunter melanjutkan dari fase M (butir 16–17 sudah ditambah
  fase M; N-01 → 18, N-02 → 19, N-03 → 20, N-M01 → 21).
- Setelah diterapkan, main chat memverifikasi tiap skill yang diubah
  (hitung baris, frontmatter, grep pola terlarang) sebelum menyatakan
  skill diperbarui — sama seperti adopsi skill baru dan penerapan
  fase J + K + M.
- Satu catatan kejujuran soal penomoran: N-04 dan N-05 TIDAK mendapat
  butir Fase 3 baru (seperti T-01/T-02 di fase M) karena penempatan
  Tier 1 + sc-audit + invariant-testing sudah menangkap keduanya
  secara penuh; N-M01 mendapat butir Fase 3 (21) karena ia metodologi
  deep-dive, bukan pola Tier.

## Langkah berikut

1. Main chat: terapkan blok N-01..N-05 + N-M01 ke tiga skill (atau
   tolak sebagian dengan alasan) → verifikasi → catat di tracker +
   inventory.
2. Setelah penerapan: ringkasan penyelesaian CTE — benchmark keempat
   selesai penuh (DVD 13/13 + Ethernaut 30/30 + CTE 14/14) — dan
   total pola terintegrasi menjadi 18 (J) + 12 (K) + 4 (M) + 6 (O)
   = 40 item.
3. Benchmark berikut: tidak ada benchmark CTF tersisa di antrean
   misi (DVD + Ethernaut + CTE selesai penuh). Langkah berikut
   adalah penerapan fase O + ringkasan CTE, lalu kembali ke
   prioritas misi: relevansi terhadap bounty aktif (tidak ada
   program DeFi workable saat ini — Sparklend CLOSED, CoW BLOCKED,
   Beanstalk PAUSED) dan pengembangan kemampuan lanjutan
   (ItyFuzz tetap TUNDA).
