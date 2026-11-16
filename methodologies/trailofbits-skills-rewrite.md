# Metodologi Trail of Bits Skills — Alur Audit & Pengujian Properti (tulis ulang)

**Sumber yang dipelajari:** trailofbits/skills — "Trail of Bits skills for
security research, vulnerability detection, and audit workflows" (lisensi
CC-BY-SA-4.0, ±8.229 bintang). Dokumen yang dibaca: README repo (daftar
plugin), `plugins/building-secure-contracts/skills/secure-workflow-guide/SKILL.md`
(penuh), dan `plugins/property-based-testing/skills/property-based-testing/SKILL.md`
(penuh), 16 November 2026.
**Status:** METODOLOGI SAJA. Tidak ada skill yang diinstal atau disalin;
tidak ada teks yang disalin verbatim. Semua uraian di bawah ini adalah rumusan
ulang dengan kata-kata sendiri dalam Bahasa Indonesia.
**Pengecualian lisensi:** Mas, 16 Nov 2026 21:13 WIB — boleh mempelajari
metodologi tool AGPL/GPL/CC-BY-SA dan menulis-ulang, tanpa mengadopsi/menyalin
kode dan tanpa menginstal tool-nya.

## Bagian A — Alur kerja aman lima langkah

Inti dari skill `secure-workflow-guide` adalah satu alur kerja yang dijalankan
berulang — pada setiap check-in, sebelum deployment, atau saat review keamanan.
Lima langkahnya:

### Langkah 1 — Pindai masalah yang sudah dikenal
Jalankan pemindai statis (Slither, 70+ detektor) atas codebase. Kelompokkan
temuan menurut severity, jelaskan tiap temuan dengan referensi file, rekomendasikan
perbaikan, dan triase false positive. Targetnya: laporan yang bersih, atau
setiap temuan yang dibiarkan memiliki triase tertulis. Pemindai statis adalah
jaring pertama — cepat dan murah — tetapi lihat file
`aderyn-static-analysis.md` untuk batas-batasnya.

### Langkah 2 — Periksa fitur khusus (hanya yang berlaku)
Tidak semua pemeriksaan berlaku untuk semua proyek — tetapi yang berlaku
harus benar-benar diperiksa:
- **Upgradeability:** periksa 17 cara upgrade bisa berjalan salah (cek
  upgradeability Slither).
- **Kesesuaian ERC:** periksa penyimpangan dari spesifikasi umum
  (6 spesifikasi yang biasa dicek).
- **Integrasi token:** bila berinteraksi dengan token pihak ketiga, gunakan
  daftar periksa integrasi token (lihat file
  `building-secure-contracts.md`).
- **Properti keamanan ERC20:** hasilkan properti otomatis untuk fitur ERC20
  dari kode yang ada.

### Langkah 3 — Inspeksi visual
Buat tiga diagram dan periksa satu per satu:
- **Graf pewarisan** — mengungkap shadowing dan masalah linearisasi C3.
- **Ringkasan fungsi** — menunjukkan visibilitas dan kontrol akses tiap
  fungsi.
- **Variabel dan otorisasi** — memetakan siapa yang bisa menulis tiap
  variabel state.
Diagram mengungkap pola yang tidak terlihat dari teks: sebuah fungsi
`onlyOwner` yang ternyata bisa dipanggil siapa saja akan langsung terlihat
di ringkasan fungsi; variabel kritis yang bisa ditulis banyak pihak akan
terlihat di peta otorisasi.

### Langkah 4 — Dokumentasikan properti keamanan (langkah terpenting)
Tuliskan properti kritis sistem sebelum menguji apa pun:
- Transisi state machine dan invariant.
- Syarat kontrol akses.
- Batas aritmetika dan presisi.
- Keamanan interaksi eksternal.
- Kesesuaian standar.
Lalu siapkan pengujian: fuzzing berbasis properti (Echidna/Medusa — padanan
kami: Foundry invariant testing), verifikasi simbolik (Manticore — padanan
kami: penalaran kasus batas manual ala Halmos, lihat
`halmos-symbolic-testing.md`), dan cek statis kustom untuk logika bisnis
proyek. Dokumen sumber menegaskan: langkah ini adalah aktivitas paling
penting untuk hasil yang baik, dan prasyarat bagi semua teknik lanjutan.

### Langkah 5 — Review manual area yang tidak bisa ditemukan tool
Empat area yang secara sistematis lolos dari tool otomatis:
- **Privasi:** rahasia di on-chain, kebutuhan commit-reveal.
- **Front-running:** perlindungan slippage, risiko ordering, MEV.
- **Kriptografi:** randomness lemah, masalah signature, tabrakan hash.
- **Interaksi DeFi:** manipulasi oracle, flash loan, asumsi protokol.
Untuk tiap area, cari polanya di codebase dan tandai risikonya. Inilah
bagian yang paling menentukan kualitas seorang auditor — dan bagian yang
paling relevan dengan bounty hunting, karena bug logic/business-logic
hidup di sini.

### Prinsip anti-rasionalisasi
Dokumen sumber memuat tabel rasionalisasi yang dilarang — semuanya bermuara
pada satu prinsip: **"tidak berlaku" tanpa verifikasi sama dengan kerentanan
yang terlewat.** Setiap langkah yang dilewati harus dibuktikan dengan
pencarian eksplisit di codebase, bukan asumsi. Contoh: "tidak ada token,
lewati cek ERC" adalah kesalahan bila ternyata ada interaksi transfer token
di suatu sudut kode. "Tidak ada interaksi DeFi, lewati cek oracle/flash
loan" adalah kesalahan bila ternyata ada price feed di suatu tempat.
Dan: jangan mengganti eksekusi workflow dengan nasihat generik — setiap
temuan harus punya referensi file dan baris.

## Bagian B — Katalog properti (pengujian berbasis properti)

Skill `property-based-testing` mengajarkan satu perbedaan mendasar: **tes contoh
menegaskan satu titik; properti menegaskan satu aturan atas seluruh domain
input**, dan membiarkan generator memburu contoh tandingan. Pertukaran ini
layak dilakukan bila kode punya "bentuk aljabar" — invers, invariant, atau
oracle. Kode yang tidak punya bentuk itu lebih baik diuji dengan tes contoh;
menyatakan hal itu secara jujur adalah hasil yang valid.

### Katalog properti
| Properti | Rumus | Berlaku untuk |
|---|---|---|
| Roundtrip | decode(encode(x)) == x | Serialisasi, pasangan konversi |
| Invers | f(g(x)) == x | Enkripsi/dekripsi, kompresi |
| Oracle | baru(x) == referensi(x) | Optimasi, refactor, reimplementasi |
| Idempotence | f(f(x)) == f(x) | Normalisasi, formatting, sorting |
| Invariant | Berlaku sebelum dan sesudah | Transformasi apa pun, state kontrak |
| Mudah diverifikasi | is_sorted(sort(x)) | Algoritma kompleks dengan checker murah |
| Komutativitas | f(a,b) == f(b,a) | Operasi biner dan himpunan |
| Asosiatif | f(f(a,b),c) == f(a,f(b,c)) | Operasi penggabungan |
| Identitas | f(x,e) == x | Operasi dengan elemen netral |

**Urutan kekuatan** (lemah ke kuat): tanpa crash → preservasi tipe →
invariant → idempotence → roundtrip/oracle. Tegaskan properti **terkuat**
yang didukung kode. "Tidak crash" saja jarang membenarkan dependensi
pengujian properti — bila hanya itu yang ditemukan, entah susunan ulang
kecil membuka properti yang lebih kuat, atau laporan jujurnya adalah kode
itu kandidat yang buruk untuk pengujian properti.

### Dua cara properti menjadi tidak menegaskan apa pun
1. **Tautologi.** Asersi yang mengulang implementasi — misalnya menguji
   `add(a,b) == a+b` dengan implementasi yang sama persis. Bug yang sama
   ada di kedua sisi, sehingga tes tidak akan pernah gagal. Pilih properti
   yang membatasi fungsi *tanpa* menghitung ulang fungsinya. Pengecualian:
   `f(x) == f(x)` adalah properti determinisme yang sah bila `f` tidak
   jelas murni — misalnya serializer atas dict/set, hashing, atau apa pun
   yang membaca jam.
2. **Vakum.** `assume` yang menyaring hampir semua input membuat tes lolos
   tanpa menguji apa pun; `assume` yang bertentangan dengan dirinya sendiri
   membuat tes lolos setelah menjalankan nol kasus. Solusinya: dorong
   batasan ke dalam strategi generator, agar generator langsung menghasilkan
   input yang valid — bukan menyaring input acak setelahnya.

### Bila kode belum punya properti
Periksa dulu apakah bentuknya hilang atau hanya terkubur: perhitungan yang
terbungkus I/O, string yang dibangun dengan konkatenasi, mutasi di tempat —
masing-masing punya properti tetapi tidak punya "celah" untuk menegaskan.
Refactor kecil untuk membuka celah itu sering kali lebih berharga daripada
menulis tes contoh tambahan.

## Bagian C — Skill pendukung lain (ringkasan)

Di luar dua skill utama di atas, plugin `building-secure-contracts` dan
plugin lain di repo yang sama memuat metodologi pendukung yang layak
dicatat — semuanya diringkas di sini dengan kata sendiri:

- **Penilai kematangan kode:** menilai codebase pada lima tingkat
  (Hilang, Lemah, Sedang, Memuaskan, Kuat) di 11 kategori — aritmetika,
  audit/monitoring, kontrol akses, manajemen kompleksitas, desentralisasi,
  dokumentasi, risiko urutan transaksi, manipulasi low-level, pengujian
  dan verifikasi, dan lain-lain. Lihat detailnya di
  `building-secure-contracts.md`.
- **Penasihat pedoman:** pedoman desain, implementasi, dan deployment
  (dokumentasi berlapis, off-chain vs on-chain, upgradeability, komposisi
  fungsi, event, dependensi, pengujian).
- **Penganalisis integrasi token:** daftar periksa saat berinteraksi dengan
  token arbitrer (ulasan keamanan, hak istimewa owner, kesesuaian ERC,
  risiko ekstensi, kelangkaan, token non-standar terkenal).
- **Asisten persiapan audit:** menyiapkan codebase agar siap direview
  pihak eksternal.
- **Pemindai kerentanan per-chain:** pola kerentanan untuk Algorand, Cairo,
  Cosmos, Solana, Substrate, TON — katalog "Not So Smart Contracts".
- **Pembangun konteks audit:** pahami codebase fungsi demi fungsi *sebelum*
  mencari bug di dalamnya — satu fungsi dalam satu waktu.
- **Verifikasi false positive:** gerbang wajib sebelum sebuah temuan
  diklaim — setiap kandidat harus lolos review gerbang.
- **Analisis dimensional:** beri anotasi satuan pada codebase untuk
  mendeteksi ketidakcocokan unit dan bug rumus.
- **Analisis varian:** cari kerentanan serupa di codebase lain dengan
  analisis berbasis pola.
- **Triase 7 brocard:** tujuh prinsip untuk menerima, menolak, atau
  meminta info lebih lanjut atas laporan kerentanan sebelum analisis
  mendalam.
- **Mutation testing:** konfigurasi mutation testing dan analisis mutan
  yang selamat — kode yang mutannya selamat adalah kode yang pengujiannya
  lemah.

## Bagian D — Pelengkap untuk invariant testing kami

Alur lima langkah menempatkan invariant testing pada tempatnya yang benar:
langkah 4 — aktivitas terpenting — dan mengingatkan bahwa fuzzing bukan
segalanya: langkah 5 (review manual) adalah tempat bug logic/business-logic
tinggal. Katalog properti memberi bahasa untuk menulis properti yang kuat:
setiap invariant yang kami tulis di fase A harus lolos dua pertanyaan —
"apakah ini tautologi?" dan "apakah assume-nya vakum?" Bila salah satu
jawabannya ya, properti itu harus ditulis ulang sebelum dipercaya.

## Bagian E — Menerapkannya dengan Foundry 1.9.0 + Slither

1. Jalankan lima langkah sebagai urutan kerja audit: Slither (langkah 1) →
   fitur khusus (langkah 2) → diagram lewat printer Slither (langkah 3) →
   dokumentasi properti + Foundry invariant testing (langkah 4) → review
   manual empat area (langkah 5).
2. Terapkan katalog properti saat menulis invariant baru: tiap invariant
   harus bisa dinamai jenis propertinya (invariant, oracle, roundtrip,
   idempotence, …) dan lolos uji tautologi/vakum.
3. Gunakan penilaian kematangan sebagai pra-cek sebelum hunt: bila codebase
   lemah di aritmetika, fokuskan invariant aritmetika; bila lemah di kontrol
   akses, fokuskan peta otorisasi.
4. Terapkan gerbang verifikasi false positive sebelum klaim apa pun —
   sejalan dengan 7-Question Gate kami (triage-validation).

## Bagian F — Testabilitas

Terapkan alur lima langkah pada kontrak lending lokal fase A dan catat waktu
serta temuan per langkah; tulis ulang properti lama dengan katalog Bagian B
dan ukur apakah properti baru menemukan kasus yang lolos dari properti lama.
Bila minimal satu langkah atau satu properti baru memberi hasil, metodologi
ini terbukti menambah nilai.

## Bagian G — Batasan

- Skill-skill ini dirancang untuk agen Claude Code — adaptasi ke Muse
  memerlukan penyesuaian alur kerja dan tool.
- Sebagian langkah merujuk tool yang tidak kami pakai (Manticore untuk
  verifikasi simbolik) — padanannya adalah penalaran kasus batas manual
  (lihat `halmos-symbolic-testing.md`).
- Lisensi CC-BY-SA-4.0 — dokumen ini adalah rumusan ulang, bukan salinan;
  atribusi sumber tetap dicantumkan di Bagian H.

## Bagian H — Sumber

- trailofbits/skills — README repo (CC-BY-SA-4.0), dibaca 16 Nov 2026.
- trailofbits/skills — `plugins/building-secure-contracts/skills/secure-workflow-guide/SKILL.md`,
  dibaca penuh 16 Nov 2026.
- trailofbits/skills — `plugins/property-based-testing/skills/property-based-testing/SKILL.md`,
  dibaca penuh 16 Nov 2026.
- Daftar plugin lain (audit-context-building, fp-check, dimensional-analysis,
  variant-analysis, vulnerability-triage-brocards, mutation-testing, dan
  lain-lain) dicatat dari README repo, 16 Nov 2026.
- Catatan: lisensi CC-BY-SA-4.0 — dokumen ini adalah rumusan ulang
  metodologi, bukan adopsi atau salinan.
