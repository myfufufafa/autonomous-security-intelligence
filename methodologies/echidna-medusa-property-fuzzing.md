# Fuzzing Berbasis Properti ala Echidna & Medusa — Metodologi (tulis ulang)

**Sumber yang dipelajari:** crytic/echidna — "Ethereum smart contract fuzzer"
(lisensi AGPL-3.0, ±3.198 bintang) dan crytic/medusa — "Parallelized,
coverage-guided, mutational Solidity smart contract fuzzing" (lisensi AGPL-3.0,
±502 bintang). Dokumen yang dibaca: README Echidna (penuh), README Medusa,
dan dokumentasi Medusa (`docs/src/testing/overview.md`,
`testing/fuzzing_lifecycle.md`, `testing/invariants.md`, `SUMMARY.md`),
16 November 2026.
**Status:** METODOLOGI SAJA. Kedua tool tidak diinstal, kode sumber tidak
diadopsi, tidak ada teks yang disalin verbatim. Semua uraian di bawah ini
adalah rumusan ulang dengan kata-kata sendiri dalam Bahasa Indonesia.
**Pengecualian lisensi:** Mas, 16 Nov 2026 21:13 WIB — boleh mempelajari
metodologi tool AGPL/GPL/CC-BY-SA dan menulis-ulang, tanpa mengadopsi/menyalin
kode dan tanpa menginstal tool-nya.

## 1. Pergeseran paradigma: fuzzing smart contract bukan mencari crash

Fuzzing tradisional (misalnya untuk binary) bertujuan menjelajahi program dengan
input acak untuk menemukan crash. Model itu tidak berlaku untuk smart contract:
kontrak tidak bisa "crash". Sebuah transaksi yang revert bukanlah crash — revert
adalah perilaku normal EVM.

Karena itu fuzzing smart contract mengubah sasaran: bukan mencari crash,
melainkan **memvalidasi invariant** — properti yang harus selalu benar —
dengan urutan transaksi acak. Definisi kerja yang dipakai: invariant adalah
kebenaran tentang sistem yang tidak berubah setelah satu atau lebih operasi
diterapkan. Contoh: jumlah semua saldo pengguna tidak pernah melebihi total
suplai token; rumus produk konstan `x·y=k` selalu berlaku untuk pool AMM;
sifat komutatif berlaku untuk library matematika.

## 2. Dua jenis invariant

**Invariant tingkat fungsi.** Properti yang muncul dari eksekusi satu fungsi
tertentu — apa yang harus benar sebelum fungsi dijalankan dan apa yang harus
benar sesudahnya. Contoh pada fungsi deposit: saldo ETH pengirim berkurang
sebesar jumlah; saldo ETH kontrak bertambah sebesar jumlah; saldo tercatat
pengirim bertambah sebesar jumlah; total yang didepositkan bertambah sebesar
jumlah.

**Invariant tingkat sistem.** Properti yang berlaku di seluruh eksekusi sistem,
tidak peduli fungsi mana yang dipanggil. Contoh: rumus `x·y=k` pada pool;
tidak ada saldo pengguna yang melebihi total suplai. Satu properti bisa
bermula di tingkat fungsi lalu naik ke tingkat sistem — misalnya "total yang
didepositkan tidak pernah melebihi batas maksimum" melibatkan deposit, withdraw,
dan stake sekaligus, sehingga lebih tepat diuji di tingkat sistem.

Pembedaan ini penting saat menulis tes: properti fungsi diuji dengan fokus
pada satu fungsi; properti sistem diuji dengan urutan panggilan acak yang
melibatkan semua fungsi.

## 3. Siklus hidup fuzzing (sebagaimana dirancang Medusa)

1. **Deployment.** Semua kontrak target di-deploy satu per satu (termasuk
   kontrak yang ter-deploy secara dinamis saat konstruksi). State blockchain
   setelah deployment ini disebut **state awal deployment** — titik nol
   sebelum fuzzer menjalankan transaksi apa pun.
2. **Generasi urutan panggilan.** Sebuah urutan panggilan adalah array
   transaksi; panjangnya dikonfigurasi. Ada dua cara menghasilkannya:
   (a) acak sepenuhnya — tiap transaksi memanggil fungsi acak dari kontrak
   target dengan argumen yang di-fuzz; (b) mutasi dari korpus (lihat §4).
   Panjang 1 berarti state dihapus tiap transaksi — berguna untuk fungsi
   murni atau library aritmetika. Panjang besar berarti state dipertahankan
   sepanjang urutan, sehingga bug yang butuh banyak langkah bisa muncul.
3. **Eksekusi iteratif.** Tiap transaksi dalam urutan dieksekusi berurutan
   pada state yang sama. Setelah tiap transaksi: perbarui coverage; bila
   coverage bertambah, simpan awalan urutan itu ke korpus; periksa apakah
   ada invariant yang dilanggar; bila ada, laporkan urutan yang gagal.
4. **Reset.** Setelah satu urutan selesai, blockchain dikembalikan ke state
   awal deployment, lalu siklus berulang dengan urutan baru.

## 4. Coverage, korpus, dan fuzzing bermutasi

**Coverage** adalah ukuran bagian kode mana yang sudah dieksekusi. Cara
kerjanya sederhana: untuk tiap kontrak target, simpan array byte sepanjang
bytecode kontrak; bila suatu transaksi mengeksekusi opcode yang belum pernah
dieksekusi, coverage bertambah.

**Korpus** adalah kumpulan urutan panggilan yang "menarik" — yaitu yang
menambah coverage. Urutan-urutan ini disimpan dan dipakai ulang, karena
terbukti mampu mencapai bagian sistem yang lebih dalam.

**Fuzzing bermutasi** (mutational fuzzing) adalah praktik mengambil sampel
yang sudah ada dari korpus dan membuat variannya — misalnya menambahkan satu
transaksi acak di akhir urutan, atau mengganti argumen. Karena urutan asal
terbukti menambah coverage, variannya punya peluang lebih besar untuk
menambah coverage lebih jauh daripada urutan yang dibuat dari nol.

Fuzzer yang bertujuan memaksimalkan coverage dengan cara ini disebut
**coverage-guided fuzzer**. Medusa menambahkan dua hal: eksekusi **paralel**
di banyak worker (thread) dan API Go untuk metodologi pengujian kustom,
plus cheatcode (warp, roll, prank, deal, snapshot, dan lain-lain) untuk
mengendalikan waktu, aktor, dan saldo dalam skenario.

## 5. Mode pengujian Echidna

Echidna menyediakan beberapa mode, dipilih lewat konfigurasi:

- **Property (default):** menguji fungsi berawalan `echidna_` yang
  mengembalikan boolean — tiap fungsi adalah satu invariant.
- **Assertion:** mendeteksi kegagalan `assert()` dan helper `assertX`
  ala Foundry (`assertTrue`, `assertEq`, dan sebagainya).
- **Foundry:** menjalankan tes gaya Foundry — unit test berawalan `test`,
  invariant berawalan `invariant` atau `statefulFuzz`; fungsi berawalan
  `check` dan `prove` adalah titik masuk simbolik, tetapi dalam mode ini
  mereka tetap di-fuzz seperti fungsi tes biasa.
- **Verification:** memverifikasi tiap fungsi secara simbolik dalam satu
  transaksi — memakai `check`/`prove` sebagai titik masuk.
- **Overflow:** mendeteksi overflow/underflow integer (Solidity ≥0.8.0).
- **Optimization:** memaksimalkan nilai balik fungsi `echidna_` yang
  mengembalikan `int256` — dipakai untuk mencari nilai terburuk suatu
  metrik, misalnya slippage terbesar atau error pembulatan terbesar.
- **Exploration:** mengumpulkan coverage tanpa memeriksa properti.

Fitur pendukung Echidna: input dibuat dari ABI kontrak (grammar-based
fuzzing — argumen disesuaikan dengan tipe dan struktur fungsi, bukan
sekadar byte acak); pra-pemindaian dengan Slither untuk mengekstrak informasi
berguna sebelum kampanye; pengumpulan dan visualisasi coverage; **minimisasi
otomatis** kasus gagal — urutan panggilan yang mematahkan invariant dipangkas
menjadi urutan terpendek yang masih gagal, agar mudah ditriase; output teks
atau JSON; integrasi CI.

## 6. Keterbatasan yang diakui

Dokumentasi Echidna sendiri mencatat keterbatasan — sebagian diwarisi dari
hevm (mesin EVM yang dipakainya), sebagian dari keputusan desain: dukungan
Vyper terbatas; dukungan library terbatas; emulasi EVM tidak sempurna.
Pelajaran umumnya: fuzzer adalah alat bantu, bukan oracle kebenaran.
Selain itu, fuzzing secara prinsip tidak bisa membuktikan ketiadaan bug —
ia hanya memberi keyakinan statistik yang tumbuh seiring waktu dan coverage.

## 7. Bedanya dengan / pelengkap untuk invariant testing Foundry (milik kami)

Foundry 1.9.0 yang kami pakai di fase A sudah memiliki invariant testing +
fuzzing. Yang ditambahkan oleh metodologi Echidna/Medusa bukanlah tool baru,
melainkan disiplin yang bisa kami terapkan di atas Foundry:

1. **Pisahkan properti fungsi dan sistem secara eksplisit.** Saat ini properti
   kami ditulis sebagai satu kumpulan invariant. Ke depan, beri label pada
   tiap invariant: fungsi atau sistem. Properti sistem diuji dengan urutan
   panjang dan semua fungsi; properti fungsi diuji dengan fokus.
2. **Korpus sebagai artefak.** Simpan urutan panggilan yang menambah coverage
   sebagai skenario tes deterministik yang tercatat (bukan sekadar angka
   coverage). Bila suatu urutan menemukan cabang baru, abadikan sebagai tes
   regresi — ia adalah bukti bahwa wilayah kode itu bisa dicapai.
3. **Minimisasi urutan gagal.** Bila invariant gagal, pangkas urutan secara
   manual: buang satu panggilan demi satu; bila invariant tetap gagal,
   panggilan itu tidak relevan — buang. Ulangi sampai tersisa urutan
   terpendek yang masih gagal. Urutan minimal adalah separuh dari laporan
   bug yang baik.
4. **Mode optimasi.** Gunakan invariant optimization Foundry (fitur v1.7+,
   sudah dicatat di fase A) untuk memaksimalkan metrik — slippage terburuk,
   error pembulatan terbesar, selisih saldo terbesar — bukan hanya
   memeriksa benar/salah. Ini adalah padanan mode optimization Echidna.
5. **Seed dari unit test.** Echidna bisa di-seed dengan unit test yang ada
   (end-to-end testing). Padanan di Foundry: jadikan skenario unit test
   penting sebagai urutan awal handler invariant.
6. **Cheatcode untuk skenario.** Gunakan cheatcode Foundry (warp, roll,
   prank, deal) untuk mengendalikan waktu dan aktor — sama seperti cheatcode
   Medusa — agar skenario yang bergantung waktu (vesting, TWAP, cooldown)
   dapat diuji.

## 8. Menerapkannya dengan Foundry 1.9.0

Langkah kerja konkret untuk hunt berikutnya:

1. Tulis properti dari spesifikasi, bukan dari implementasi (hindari
   tautologi — lihat `trailofbits-skills-rewrite.md`).
2. Bagi properti menjadi fungsi vs sistem; tulis keduanya.
3. Jalankan kampanye fuzzing dengan jumlah runs tinggi dan seed berbeda;
   catat coverage (laporan Foundry) dan simpan urutan penambah coverage
   sebagai tes deterministik.
4. Bila invariant gagal: minimalkan urutan, lalu tulis PoC minimal dari
   urutan itu (format yang sama dengan PoC Sparklend/Safe kami).
5. Bila invariant lolos: catat jumlah runs + coverage yang dicapai — dan
   tetap nyatakan dengan jujur bahwa itu bukan bukti ketiadaan bug.

## 9. Testabilitas

Terapkan disiplin §7–§8 pada kontrak lending lokal fase A dan ukur:
jumlah properti fungsi vs sistem yang ditulis; apakah ada urutan penambah
coverage yang bila diabadikan menemukan cabang baru; apakah minimisasi
manual mempersingkat urutan gagal dari fase A; dan apakah mode optimasi
menemukan nilai metrik terburuk yang belum terlihat. Bila minimal satu
dari empat itu memberi hasil, metodologi ini terbukti menambah nilai.

## 10. Batasan

- Fuzzing tidak membuktikan ketiadaan bug; coverage tinggi bukan jaminan.
- Properti yang salah (tautologi atau vakum) memberi rasa aman palsu —
  properti yang buruk lebih berbahaya daripada tidak ada properti.
- Urutan panjang yang gagal sulit dipahami tanpa minimisasi.
- Butuh waktu komputasi besar untuk ruang state yang besar; paralelisasi
  Medusa tidak kami miliki — gantinya adalah runs yang lebih lama atau
  membagi properti ke beberapa kampanye.

## 11. Sumber

- crytic/echidna — README repo (AGPL-3.0), dibaca penuh 16 Nov 2026.
- crytic/medusa — README repo (AGPL-3.0), dibaca 16 Nov 2026.
- crytic/medusa — `docs/src/testing/overview.md`, `testing/fuzzing_lifecycle.md`,
  `testing/invariants.md`, `SUMMARY.md`, dibaca penuh 16 Nov 2026.
- Catatan: lisensi AGPL-3.0 — dokumen ini adalah rumusan ulang metodologi,
  bukan adopsi atau salinan kode.
