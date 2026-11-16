# Building Secure Contracts — Metodologi (tulis ulang)

**Sumber yang dipelajari:** crytic/building-secure-contracts — buku "Building
Secure Contracts" oleh Trail of Bits (lisensi AGPL-3.0, ±2,5K bintang),
situs https://secure-contracts.com. Dokumen yang dibaca: `SUMMARY.md`,
`development-guidelines/guidelines.md` (pedoman tingkat tinggi),
`development-guidelines/workflow.md` (alur kerja),
`development-guidelines/rekt-test.md` (12 pertanyaan),
`development-guidelines/token_integration.md` (daftar periksa token),
dan bagian awal `development-guidelines/code_maturity.md` (model kematangan),
16 November 2026.
**Status:** METODOLOGI SAJA. Buku tidak diadopsi atau disalin; tidak ada teks
yang disalin verbatim. Semua uraian di bawah ini adalah rumusan ulang dengan
kata-kata sendiri dalam Bahasa Indonesia.
**Pengecualian lisensi:** Mas, 16 Nov 2026 21:13 WIB — boleh mempelajari
metodologi tool AGPL/GPL/CC-BY-SA dan menulis-ulang, tanpa mengadopsi/menyalin
kode dan tanpa menginstal tool-nya.

## 1. Struktur buku

Buku ini tersusun dalam lima bagian besar:

1. **Pedoman Pengembangan** — kriteria kematangan kode, praktik terbaik
   tingkat tinggi, rekomendasi respons insiden, alur kerja pengembangan
   yang aman, daftar periksa integrasi token, persiapan review keamanan,
   dan Uji Rekt.
2. **Belajar EVM** — pengetahuan teknis tentang EVM: referensi opcode,
   penelusuran transaksi, pemeriksaan aritmetika, panduan Yellow Paper,
   ringkasan EIP per fork.
3. **Not So Smart Contracts** — contoh kerentanan nyata per chain
   (Algorand, Cairo, Cosmos, Solana, Substrate, Sui, TON), masing-masing
   dengan deskripsi, contoh, dan rekomendasi.
4. **Analisis Program** — tutorial dan latihan untuk empat tool:
   Echidna, Medusa, Slither, dan Manticore — masing-masing dengan
   pengantar teori, tur API, dan latihan sekitar dua jam.
5. **Sumber daya** — daftar tulisan blog Trail of Bits tentang blockchain.

Untuk bounty hunting, bagian 1 dan 4 adalah yang paling relevan; bagian 3
berfungsi sebagai katalog pola lintas-chain.

## 2. Model kematangan kode

Buku ini menilai codebase pada **11 kategori** — antara lain aritmetika,
audit/monitoring, kontrol akses/autentikasi, manajemen kompleksitas,
desentralisasi, dokumentasi, risiko urutan transaksi, manipulasi low-level,
serta pengujian dan verifikasi. Tiap kategori dinilai dalam **lima tingkat**:

- **Hilang** — tidak ada / tidak diterapkan.
- **Lemah** — banyak area perbaikan yang signifikan.
- **Sedang** — prosedurnya memadai, tetapi bisa ditingkatkan.
- **Memuaskan** — di atas rata-rata, tetapi masih bisa ditingkatkan.
- **Kuat** — hanya sedikit area perbaikan potensial.

Aturan penilaiannya bertingkat: bila ada kriteria Lemah yang berlaku, nilainya
Lemah; bila tidak ada kriteria Lemah tetapi sebagian kriteria Sedang berlaku,
nilainya Sedang; dan seterusnya sampai Kuat, yang mensyaratkan semua kriteria
tingkat bawah terpenuhi plus bukti praktik luar biasa.

Dua contoh kategori (diringkas dengan kata sendiri):

**Aritmetika.** Tingkat Lemah ditandai tidak adanya perlindungan overflow
yang eksplisit tanpa pembenaran; pemakaian `unchecked` yang tidak
didokumentasikan; rumus tanpa spesifikasi (atau spesifikasi yang tidak cocok
dengan kode); dan pengujian yang tidak mencakup edge case aritmetika.
Tingkat yang lebih tinggi menuntut: pembulatan eksplisit (ke atas atau ke
bawah) pada semua operasi yang kehilangan presisi; risiko pembulatan
didokumentasikan; kerugian presisi dianalisis terhadap ground truth
aritmetika presisi tak terbatas dan dibatasi; semua operasi trapping
(overflow, bagi nol) teridentifikasi beserta dampaknya; spesifikasi rumus
cocok satu-satu dengan kode; dan teknik pengujian otomatis mencakup semua
operasi aritmetika signifikan dan berjalan berkala, idealnya di CI.

**Audit/monitoring.** Tingkat Lemah: tidak ada strategi event — event hilang
untuk update komponen kritis, tidak ada pedoman yang konsisten tentang fungsi
mana yang memancarkan event, event yang sama dipakai ulang untuk tujuan
berbeda. Tingkat yang lebih tinggi: event dipancarkan untuk semua fungsi
kritis; ada infrastruktur off-chain yang mencatat event dan rencana monitoring;
dokumentasi menjelaskan tujuan tiap event dan cara menggunakannya; ada rencana
respons insiden; sistem monitoring memicu notifikasi/alarm saat perilaku tak
terduga; ada peran dan tanggung jawab yang jelas; rencana respons insiden
diuji secara berkala lewat latihan.

**Kegunaan untuk bounty hunting:** nilai kematangan sebuah protokol target
*sebelum* berburu. Protokol dengan skor Lemah di aritmetika adalah kandidat
kuat untuk invariant aritmetika dan pengujian properti; protokol dengan skor
Lemah di kontrol akses adalah kandidat untuk pemetaan otorisasi; protokol
dengan skor Lemah di audit/monitoring berarti bug yang ditemukan akan lebih
sulit terdeteksi oleh tim — tetapi juga berarti permukaan serangan lebih luas.

## 3. Pedoman tingkat tinggi (diringkas)

**Desain.**
- Diskusikan desain sebelum menulis kode.
- Dokumentasi berlapis: deskripsi sistem dalam bahasa biasa (tujuan kontrak
  dan asumsi), skema dan diagram arsitektur termasuk interaksi kontrak dan
  state machine (printer Slither dapat membantu membuatnya), serta
  dokumentasi kode menyeluruh dalam format NatSpec.
- Simpan komputasi berat di off-chain; buat verifikasi on-chain sesederhana
  mungkin. Perlu daftar terurut? Urutkan off-chain, lalu periksa urutannya
  on-chain.
- Putuskan soal upgradeability *sebelum* menulis kode — keputusan ini
  memengaruhi struktur. Anjuran buku: utamakan **migrasi kontrak** daripada
  upgradeability; bila perlu upgrade, pola **pemisahan data** lebih aman
  daripada proxy delegatecall. Bila memakai proxy delegatecall: samakan
  layout storage (warisi semua variabel state dari kontrak dasar bersama,
  karena urutan pewarisan memengaruhi layout); inisialisasi implementation
  segera (pola factory membantu); waspadai shadowing fungsi (fungsi proxy
  yang sama namanya dengan fungsi implementation tidak akan terpanggil);
  cegah pemakaian langsung implementation (buat semua metode revert);
  waspadai variabel immutable/constant yang bisa tidak sinkron antara proxy
  dan implementation; verifikasi keberadaan kontrak pada semua low-level
  call (termasuk delegatecall — call ke alamat tanpa bytecode tetap
  mengembalikan true).

**Implementasi.**
- Sederhana adalah tujuan: solusi paling sederhana yang memenuhi kebutuhan,
  dan harus dipahami semua anggota tim.
- Bagi logika sistem (beberapa kontrak, atau kelompok fungsi sejenis seperti
  autentikasi dan aritmetika); tulis fungsi kecil dengan tujuan yang jelas.
- Jaga pewarisan tetap terkendali (dangkal dan sempit); periksa hierarki
  dengan inheritance printer.
- Catat semua operasi kritis dalam event — membantu debugging saat
  pengembangan dan monitoring setelah deployment.
- Kenali jebakan umum (Ethernaut, Capture the Ether, Not So Smart Contracts,
  dan bagian peringatan di dokumentasi Solidity).
- Pakai library yang teruji (misalnya OpenZeppelin untuk ERC20) dan
  dependency manager — jangan salin-tempel kode eksternal.
- Tulis unit test yang menyeluruh; buat cek Slither dan properti Echidna
  kustom; pelajari cara menulis properti yang efisien.
- Hindari inline assembly kecuali sudah menguasai Yellow Paper.
- Pilih versi Solidity yang stabil dan direkomendasikan; kompilasi dengan
  rilis stabil, tetapi periksa warning dengan rilis terbaru.

**Deployment.**
- Monitor kontrak setelah deploy; siapkan respons bila kontrak atau wallet
  terkompromi.
- Cantumkan kontak di daftar kontak keamanan blockchain agar pihak ketiga
  bisa memberitahu bila menemukan celah.
- Amankan wallet pengguna privileged (hardware wallet).
- Kembangkan rencana respons insiden — asumsikan kontrak *bisa* dikompromikan.

## 4. Alur kerja pengembangan yang aman

Buku ini merumuskan alur lima langkah yang sama dengan skill
secure-workflow-guide di file `trailofbits-skills-rewrite.md` — di sini
diringkas agar file ini berdiri sendiri:

1. **Periksa masalah yang sudah dikenal** — jalankan Slither pada setiap
   check-in; targetnya laporan bersih atau triase tertulis.
2. **Periksa fitur khusus** — upgradeability (17 cara upgrade bisa salah),
   kesesuaian ERC (6 spesifikasi), properti ERC20 otomatis, dan daftar
   periksa integrasi token.
3. **Inspeksi visual** — tiga diagram Slither: graf pewarisan,
   ringkasan fungsi, dan variabel + otorisasi.
4. **Dokumentasikan properti keamanan** — aktivitas paling penting; fokus
   pada state machine, kontrol akses, aritmetika, interaksi eksternal, dan
   kesesuaian standar; lalu uji dengan fuzzing dan verifikasi.
5. **Waspadai yang tidak bisa ditemukan tool** — privasi, front-running,
   kriptografi, dan interaksi DeFi yang berisiko.

## 5. Daftar periksa integrasi token (diringkas)

Saat sebuah protokol berinteraksi dengan token arbitrer, periksa:

- **Pertimbangan umum:** token sudah pernah direview keamanannya? Bisa
  menghubungi tim pengembangnya? Ada mailing list keamanan untuk pengumuman
  kritis?
- **Komposisi kontrak:** token tidak terlalu kompleks; memakai SafeMath;
  hanya sedikit fungsi non-token; hanya satu alamat (beberapa titik masuk
  untuk update saldo dapat merusak pembukuan internal).
- **Hak istimewa owner:** token tidak upgradeable; kemampuan mint terbatas;
  tidak pausable; owner tidak bisa mem-blacklist kontrak kita; tim di
  baliknya dikenal dan dapat dimintai tanggung jawab.
- **Kesesuaian ERC20:** `transfer`/`transferFrom` mengembalikan boolean;
  `name`/`decimals`/`symbol` ada bila dipakai; `decimals` mengembalikan
  `uint8`; race condition approval ERC20 yang sudah dikenal sudah
  dimitigasi; kontrak lolos unit test dan properti keamanan hasil
  `slither-prop`.
- **Risiko ekstensi:** bukan token ERC777 dan tidak ada panggilan eksternal
  di `transfer`/`transferFrom` (risiko reentrancy); transfer tidak memungut
  fee (token deflasioner berperilaku tak terduga); bunga yang diperoleh
  token sudah diperhitungkan (jangan sampai terjebak di kontrak).
- **Kelangkaan:** suplai tidak dimiliki segelintir pengguna; total suplai
  cukup; token tersebar di banyak exchange; sadar bahwa saldo bisa berubah
  drastis lewat dana besar atau flash loan; token tidak mengizinkan flash
  minting.
- **Token non-standar terkenal:** ada daftar token terkenal yang menyimpang
  dari standar — periksa daftar itu sebelum mengintegrasikan.
- **ERC721:** transfer ke alamat nol harus revert; `safeTransferFrom`
  dengan signature yang benar; `ownerOf` revert untuk tokenId tidak valid
  atau sudah dibakar; transfer membersihkan approval; tokenId tidak berubah
  sepanjang hidupnya; callback `onERC721Received` diperhitungkan (risiko
  reentrancy, termasuk lewat `safeMint`); mint ke smart contract dilakukan
  dengan aman; burn membersihkan approval.

## 6. Uji Rekt — 12 pertanyaan penilaian cepat

Uji Rekt adalah kerangka penilaian keamanan yang terinspirasi dari Joel Test
— 12 pertanyaan yang dijawab ya/tidak, di mana "ya" membutuhkan bukti, bukan
sekadar niat. Semakin banyak jawaban ya, semakin dapat dipercaya kualitas
operasi keamanan organisasi itu. Pertanyaannya (diringkas dengan kata sendiri):

**Dokumentasi dan perencanaan**
1. Apakah semua aktor, peran, dan hak istimewa terdokumentasi?
2. Apakah dokumentasi semua layanan, kontrak, dan oracle eksternal yang
   diandalkan selalu diperbarui?
3. Apakah ada rencana respons insiden yang tertulis dan sudah diuji?
4. Apakah cara-cara menyerang sistem didokumentasikan (threat model)?

**Personel dan kontrol akses**
5. Apakah identitas dan latar belakang semua karyawan diverifikasi?
6. Apakah ada anggota tim yang perannya secara eksplisit mencakup keamanan?
7. Apakah kunci keamanan hardware diwajibkan untuk sistem produksi?
8. Apakah manajemen kunci membutuhkan banyak manusia dan langkah fisik
   (misalnya multisig — tidak ada satu orang yang bisa mengompromikan sistem)?

**Keamanan teknis**
9. Apakah invariant kunci didefinisikan dan diuji pada setiap commit?
10. Apakah tool otomatis terbaik digunakan untuk menemukan masalah
    keamanan (analisis statis + fuzzing)?
11. Apakah audit eksternal dilakukan dan program disclosure/bug bounty
    dipelihara?
12. Apakah jalur penyalahgunaan terhadap pengguna sudah dipertimbangkan dan
    dimitigasi (phishing, social engineering, serangan ekonomi)?

Cara pakai: nilai awal dengan jujur; pertanyaan yang tidak bisa dijawab ya
adalah area perbaikan; prioritaskan menurut profil risiko; tinjau ulang
secara berkala, terutama setelah perubahan besar.

**Kegunaan untuk bounty hunting:** pertanyaan 9 dan 10 adalah yang paling
relevan untuk kami — protokol yang menjawab "tidak" pada keduanya adalah
protokol yang invariant-nya belum pernah diuji secara sistematis, alias
target yang lebih menjanjikan. Pertanyaan 4 (threat model) juga penting:
bila tim tidak pernah mendokumentasikan cara menyerang sistemnya sendiri,
kemungkinan besar ada jalur serangan yang belum mereka pikirkan.

## 7. Analisis program — struktur latihan

Untuk tiap tool (Echidna, Medusa, Slither, Manticore), buku ini menyediakan
materi pelatihan dengan pola yang sama: pengantar teori, tur API, dan latihan
sekitar dua jam. Untuk Echidna, latihannya mencakup: memilih mode pengujian,
memilih pendekatan pengujian, memfilter fungsi, memeriksa asersi, menulis
properti yang baik langkah demi langkah, bekerja dengan ether, mengumpulkan
korpus, mode optimasi, fuzzing skala besar, menguji kontrak bytecode-only,
cheatcode, seed dari unit test, `allContracts`, library eksternal, forking
state on-chain, dan FFI ke data off-chain. Metodologi Echidna dan Medusa
sudah diringkas dalam file `echidna-medusa-property-fuzzing.md`; Slither
sudah kami pakai; Manticore (verifikasi simbolik) tidak kami instal —
padanannya adalah penalaran kasus batas manual (lihat
`halmos-symbolic-testing.md`).

## 8. Not So Smart Contracts — katalog pola lintas-chain

Bagian ini mengumpulkan contoh kerentanan nyata per chain — Algorand
(rekeying, fee tak diperiksa, penutupan akun/aset, ukuran grup, replay
berbasis waktu, kontrol akses, cek asset ID, denial of service),
Cairo (overflow aritmetika, konversi alamat L1↔L2, replay signature),
Cosmos (signer salah, non-determinisme, prioritas pesan, panic ABCI,
pembukuan rusak, error pembulatan), Solana (CPI arbitrer, validasi PDA,
cek kepemilikan, cek signer, cek sysvar), Substrate (overflow, panic,
bobot dan fee, asal buruk, randomness buruk), Sui, dan TON.
Masing-masing contoh dilengkapi deskripsi, contoh, dan rekomendasi.
Untuk bounty hunting EVM, nilai bagian ini terutama sebagai *pengingat
pola*: banyak bug lintas-chain adalah varian dari tema yang sama —
validasi yang terlewat, asumsi tentang identitas/pemilik, dan pembulatan.

## 9. Pelengkap untuk invariant testing kami

Buku ini menempatkan invariant testing sebagai aktivitas terpenting (langkah
4 alur kerja + pertanyaan 9 Uji Rekt) — tetapi memberi konteks yang tidak
dimiliki fuzzing semata: model kematangan untuk menilai target, daftar
periksa token untuk interaksi eksternal, dan katalog pola lintas-chain.
Untuk hunt berikutnya, gunakan tiga alat penilaian ini *sebelum* menulis
invariant: (1) Uji Rekt + kematangan untuk memilih target dan area fokus;
(2) daftar periksa integrasi token saat menilai interaksi protokol dengan
token eksternal (sering menjadi sumber bug oracle/pembulatan);
(3) katalog Not So Smart Contracts sebagai sumber ide pola yang belum ada
di checklist kami.

## 10. Menerapkannya dengan Foundry 1.9.0 + Slither

1. **Pra-penilaian target:** nilai protokol dengan Uji Rekt dan model
   kematangan; fokuskan invariant pada kategori yang Lemah.
2. **Checklist token:** saat protokol berinteraksi dengan token eksternal,
   jalankan daftar periksa §5 — tiap item yang tidak terpenuhi adalah
   hipotesis bug.
3. **Latihan analisis program:** ganti Echidna/Medusa dengan Foundry
   invariant testing, dan Manticore dengan penalaran kasus batas manual;
   kerjakan latihan dengan pola yang sama (teori → tur → latihan).
4. **Katalog pola:** ekstrak pola dari Not So Smart Contracts ke
   `vulnerability-patterns/` bila relevan dengan EVM.

## 11. Testabilitas

Nilai kontrak lending lokal fase A dengan Uji Rekt dan model kematangan;
bandingkan skornya dengan hasil invariant testing fase A. Bila kategori
yang dinilai Lemah berkorelasi dengan tempat ditemukannya pelanggaran
invariant (atau sebaliknya — kategori Kuat tidak pernah bermasalah),
model penilaian ini terbukti punya daya prediksi. Catat hasilnya di
laporan fase berikut.

## 12. Batasan

- Buku berlabel versi 0.1.0 — sebagian konten menua (misalnya anjuran
  SafeMath yang berasal dari era pra-Solidity 0.8; beberapa tautan dan
  versi tool sudah berubah).
- Lisensi AGPL-3.0 — dokumen ini adalah rumusan ulang, bukan salinan.
- Latihan tool Echidna/Medusa/Manticore tidak dijalankan (tool tidak
  diinstal); yang diambil adalah struktur latihannya.

## 13. Sumber

- crytic/building-secure-contracts — `SUMMARY.md`, dibaca 16 Nov 2026.
- crytic/building-secure-contracts — `development-guidelines/guidelines.md`,
  `workflow.md`, `rekt-test.md`, `token_integration.md`, dibaca penuh
  16 Nov 2026.
- crytic/building-secure-contracts — `development-guidelines/code_maturity.md`
  (bagian awal, via https://secure-contracts.com/print.html), dibaca
  16 Nov 2026.
- Situs buku: https://secure-contracts.com (AGPLv3).
- Catatan: lisensi AGPL-3.0 — dokumen ini adalah rumusan ulang metodologi,
  bukan adopsi atau salinan.
