# Analisis Statis ala Aderyn — Metodologi (tulis ulang)

**Sumber yang dipelajari:** Cyfrin/aderyn — "Solidity Static Analyzer"
(lisensi GPL-3.0, ±809 bintang, 828 commit). Dokumen yang dibaca: README repo
(penuh) dan daftar detektor dari struktur repo (`aderyn_core/src/detect/high`,
`aderyn_core/src/detect/low`), 16 November 2026.
**Status:** METODOLOGI SAJA. Tool tidak diinstal, kode sumber tidak diadopsi,
tidak ada teks yang disalin verbatim. Semua uraian di bawah ini adalah rumusan
ulang dengan kata-kata sendiri dalam Bahasa Indonesia.
**Pengecualian lisensi:** Mas, 16 Nov 2026 21:13 WIB — boleh mempelajari
metodologi tool AGPL/GPL/CC-BY-SA dan menulis-ulang, tanpa mengadopsi/menyalin
kode dan tanpa menginstal tool-nya.

## 1. Peringatan penting: proyek ini sudah pensiun

Fakta pertama yang harus dicatat: **Aderyn sudah retired dan tidak lagi
di-maintain.** Tidak ada lagi jalur instalasi atau upgrade yang didukung;
dokumentasi dipertahankan hanya sebagai referensi historis, dan ekstensi
VS Code-nya sudah dihapus dari marketplace. Artinya: metodologi di bawah ini
tetap berharga sebagai *daftar periksa dan taksonomi*, tetapi tool-nya tidak
boleh dijadikan andalan — detektornya tidak akan diperbarui untuk pola
kerentanan baru. Untuk eksekusi analisis statis, kami tetap memakai Slither
(yang sudah dimiliki dan dipakai di hunt Safe + Sparklend).

## 2. Inti metode: membaca kode tanpa menjalankannya

Analisis statis memeriksa kode sumber tanpa mengeksekusinya. Cara kerja
Aderyn, diringkas dari arsitekturnya:

1. **Kompilasi menjadi AST.** Kode Solidity dikompilasi (memakai backend
   kompiler Foundry) menjadi *abstract syntax tree* — representasi
   terstruktur dari program: kontrak, fungsi, variabel, ekspresi, dan
   hubungan di antaranya.
2. **Penelusuran AST.** Sebuah visitor menelusuri pohon AST simpul demi
   simpul.
3. **Pencocokan pola detektor.** Tiap detektor adalah aturan yang mengenali
   satu pola bermasalah di AST — misalnya "panggilan low-level tanpa
   pengecekan hasil", atau "variabel state yang dibayangi oleh variabel
   lokal". Bila pola cocok, detektor mencatat temuan beserta lokasinya.
4. **Pelaporan.** Temuan dikelompokkan menurut severity dan dilaporkan dalam
   format Markdown, JSON, atau SARIF. Detektor kustom bisa ditulis sendiri
   dengan pola yang sama.

Kuncinya: analisis statis hanya melihat *bentuk* kode, bukan *perilakunya*
saat berjalan. Ia tidak tahu nilai saldo pada satu titik waktu, tidak tahu
urutan panggilan yang akan dilakukan penyerang, dan tidak tahu maksud ekonomi
protokol. Kekuatan dan kelemahannya sama-sama berasal dari sini.

## 3. Taksonomi detektor (diringkas dari 40 detektor high + 50 detektor low)

Daftar berikut adalah pengelompokan ulang dari nama-nama detektor Aderyn
menjadi kelompok yang bermakna untuk reviewer manusia. Bukan salinan daftar —
melainkan taksonomi kerja.

### A. Kontrol akses & otorisasi
- Autentikasi memakai `tx.origin` (bukan `msg.sender`).
- Fungsi initializer yang tidak terlindungi (proxy bisa diinisialisasi ulang
  oleh siapa saja).
- `delegatecall` ke alamat yang tidak diperiksa.
- Pengiriman ETH ke alamat yang tidak diperiksa; `send` tanpa pengecekan.
- Panggilan low-level tanpa pengecekan hasil.
- Perubahan state setelah interaksi eksternal (pola reentrancy).
- `selfdestruct` yang dapat dijangkau.

### B. Aritmetika & presisi
- Casting yang tidak aman (menyempitkan tipe tanpa pemeriksaan).
- Urutan operasi shift yang salah; operator `^` yang dipakai seolah-olah
  pangkat; operator unary yang berbahaya.
- Perbandingan yang selalu benar atau selalu salah (tautologi/kontradiksi).
- Pembagian sebelum perkalian (kehilangan presisi).
- Literal numerik besar yang rawan salah baca.

### C. Standar token (ERC)
- Interface ERC20/ERC721 yang tidak sesuai standar.
- `transferFrom` sembarangan (memindahkan token dari alamat mana pun).
- Operasi ERC20 yang tidak aman; mint ERC721 yang tidak aman.
- Pemakaian library transfer yang sudah dikenal bermasalah.

### D. Upgradeability & proxy
- Shadowing variabel state (variabel di kontrak turunan menutupi variabel
  induk — berbahaya pada layout storage proxy).
- Penghapusan mapping bersarang; array di storage yang diedit lewat memory.
- Beberapa konstruktor; nama kontrak yang dipakai ulang.
- Inisialisasi state di dalam fungsi biasa (bukan konstruktor).
- Array integer bertanda di storage.

### E. Logika & bahasa
- Boolean yang disalahgunakan; kesetaraan ketat (strict equality) pada
  saldo kontrak (saldo bisa dipaksa berubah lewat `selfdestruct` atau
  coinbase).
- Randomness yang lemah (mengandalkan block timestamp / prevrandao).
- Tabrakan selektor fungsi; tabrakan hash `abi.encodePacked`.
- Pengembalian dari assembly (Yul) yang tidak benar.
- RTLO (karakter pengubah arah teks — serangan visual pada kode).
- Fungsi dengan nilai `msg.value` di dalam loop.
- Fungsi `delete` pada mapping bersarang (tidak menghapus seperti yang
  diharapkan).

### F. Kualitas, gas & kebersihan
- Dead code, impor tak terpakai, fungsi publik tak terpakai, variabel state
  tak terpakai, error tak terpakai.
- Loop yang mahal; panjang array storage yang tidak di-cache.
- Variabel state yang seharusnya `constant`/`immutable`.
- Urutan inisialisasi variabel state; pembacaan variabel state dari fungsi
  eksternal; konstruktor kosong; pragma Solidity yang tidak spesifik;
  `TODO` yang tertinggal; `require`/`revert` di dalam loop; return bomb
  (nilai balik besar yang menghabiskan gas pemanggil); pemeriksaan
  `ecrecover` yang tidak lengkap; deadline berbasis block timestamp.

## 4. Apa yang BISA dideteksi — dan apa yang TIDAK

**Bisa:** pola sintaksis yang sudah dikenal; pelanggaran standar token;
masalah struktural (shadowing, inisialisasi, layout storage, pewarisan);
pemeriksaan kepatuhan ERC; masalah kebersihan dan gas. Analisis statis
cepat, murah, dan deterministik — ia memeriksa seluruh codebase dalam
hitungan detik.

**Tidak bisa** (ini batas yang paling penting untuk bounty hunter):

- **Logika bisnis protokol.** Apakah rumus bunga benar? Apakah kurva
  insentif menciptakan serangan ekonomi? Analisis statis tidak tahu maksud
  ekonomi — ia hanya tahu bentuk kode.
- **Invariant protokol.** Apakah total saldo selalu sama dengan total suplai
  dalam segala urutan panggilan? Itu pertanyaan tentang perilaku runtime,
  bukan bentuk sintaksis.
- **Manipulasi oracle/harga.** Apakah harga yang dibaca bisa dimanipulasi
  lewat flash loan? Butuh penalaran tentang pasar, bukan AST.
- **Error pembulatan yang bergantung nilai.** Apakah pembulatan merugikan
  pengguna pada nilai tertentu? Butuh nilai konkret, bukan pola.
- **Tabrakan storage pada upgrade** yang membutuhkan penalaran lintas
  kontrak dan lintas versi.
- **Reentrancy lintas kontrak.** Reentrancy dalam satu kontrak bisa
  dideteksi polanya; reentrancy yang melibatkan dua kontrak atau lebih
  dengan callback tidak terlihat dari satu AST.
- **Kontrol akses yang "benar secara sintaksis tapi salah secara maksud".**
  Modifier ada, tetapi peran yang diberikannya salah — itu keputusan
  desain, bukan pola kode.

Catatan yang sama muncul dari sumber lain (skill aeon sc-audit): pemindai
statis seperti Slither lemah pada kontrol akses, invariant protokol,
manipulasi oracle/harga, pembulatan, tabrakan storage upgradeability, dan
reentrancy lintas-kontrak — persis kelas bug yang paling banyak menguras
dana. Analisis statis adalah **jaring pertama, bukan jaring terakhir.**

## 5. Urutan kerja yang benar

1. **Baca kode + petakan arsitektur dulu.** Pahami tujuan tiap fungsi
   sebelum menjalankan tool apa pun.
2. **Jalankan pemindai statis sebagai penyaring.** Slither (milik kami)
   atas seluruh codebase; kelompokkan temuan menurut severity.
3. **Triase manual.** Konfirmasi tiap temuan: benarkah ini bug, atau false
   positive? Dokumentasikan alasan penolakan — jangan diam-diam mengabaikan.
4. **Fokuskan waktu manusia pada yang tidak terdeteksi.** Tulis invariant
   untuk logika bisnis; jalankan fuzzing; lakukan review manual untuk
   kelas di §4 (oracle, rounding, ekonomi, lintas-kontrak).
5. **Ulangi.** Setiap perubahan kode → pindai ulang; temuan baru dari
   fuzzing → cek apakah ada pola statis yang seharusnya menangkapnya.

## 6. Menerapkannya dengan Foundry 1.9.0 + Slither (tanpa Aderyn)

Yang kami adopsi dari Aderyn bukanlah tool-nya, melainkan **taksonomi
detektornya sebagai daftar periksa review manual**:

- Saat membaca sebuah kontrak, jalankan taksonomi §3 sebagai checklist:
  per kelompok (A–F), tanyakan apakah pola itu ada di kode yang dibaca.
- Kelompok A–D adalah prioritas (dampak keamanan langsung); kelompok F
  adalah pelengkap (kualitas/gas — kadang menyembunyikan bug logika).
- Bandingkan dengan hasil Slither: bila Slither tidak melaporkan apa pun
  pada satu kelompok, bukan berarti kelompok itu bersih — periksa manual.
- Detektor kustom: bila sebuah pola bug ditemukan lewat fuzzing/replay
  (misalnya dari DeFiHackLabs), rumuskan polanya sebagai item checklist
  baru di `vulnerability-patterns/` — ini adalah cara kami "menulis
  detektor sendiri" tanpa tool.

## 7. Testabilitas

Terapkan taksonomi §3 sebagai checklist pada kontrak lending lokal fase A:
hitung berapa item checklist yang relevan, berapa yang benar-benar ada
(true positive), dan berapa yang ternyata bukan masalah (false positive).
Bandingkan hasilnya dengan laporan Slither atas kontrak yang sama. Bila
checklist manual menemukan minimal satu hal yang Slither lewatkan, taksonomi
ini terbukti menambah nilai. Catat hasilnya di laporan fase berikut.

## 8. Batasan

- **Proyek pensiun** — detektor tidak diperbarui; pola serangan baru tidak
  akan ditangkap.
- **False positive tinggi**, terutama pada detektor tingkat rendah — triase
  manual wajib; laporan mentah tool tidak boleh langsung dijadikan laporan
  bug.
- **Tidak mengerti semantik ekonomi** — semua bug logic/business-logic
  lolos dari jaring ini secara desain.
- **Bergantung pada AST yang benar** — kode yang tidak terkompilasi dengan
  bersih tidak bisa dianalisis.

## 9. Sumber

- Cyfrin/aderyn — README repo (GPL-3.0), dibaca penuh 16 Nov 2026.
- Cyfrin/aderyn — struktur detektor `aderyn_core/src/detect/high`
  (40 file) dan `aderyn_core/src/detect/low` (50 file), dibaca
  16 Nov 2026.
- Catatan: lisensi GPL-3.0; proyek berstatus retired. Dokumen ini adalah
  rumusan ulang metodologi dan taksonomi, bukan adopsi atau salinan kode.
