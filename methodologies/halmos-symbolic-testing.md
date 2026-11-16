# Pengujian Simbolik ala Halmos — Metodologi (tulis ulang)

**Sumber yang dipelajari:** a16z/halmos — "A symbolic testing tool for EVM smart
contracts" (lisensi AGPL-3.0, ±1.043 bintang). Dokumen yang dibaca: README repo dan
panduan "How to write symbolic tests with Halmos" (`docs/getting-started.md`),
16 November 2026.
**Status:** METODOLOGI SAJA. Tool tidak diinstal, kode sumber tidak diadopsi,
tidak ada teks yang disalin verbatim. Semua uraian di bawah ini adalah rumusan
ulang dengan kata-kata sendiri dalam Bahasa Indonesia.
**Pengecualian lisensi:** Mas, 16 Nov 2026 21:13 WIB — boleh mempelajari metodologi
tool AGPL/GPL/CC-BY-SA dan menulis-ulang, tanpa mengadopsi/menyalin kode dan
tanpa menginstal tool-nya.

## 1. Inti metode: simbol, bukan sampel

Fuzzing biasa bekerja dengan sampel: ia memilih nilai input secara acak, menjalankan
kontrak, lalu memeriksa hasilnya. Kelemahannya, nilai langka yang memicu cabang
kode tertentu bisa tidak pernah terpilih — misalnya nilai persis yang membuat
sebuah perbandingan menjadi benar, atau alamat yang sama persis dengan alamat lain.

Pengujian simbolik membalik pendekatan itu. Setiap input tidak diisi satu nilai
acak, melainkan diwakili sebuah **simbol** — yaitu lambang yang berdiri untuk
*seluruh himpunan nilai yang mungkin* dari tipe tersebut. Sebuah simbol bilangan
256-bit berarti semua bilangan dari nol sampai 2^256−1 sekaligus; sebuah simbol
alamat berarti semua alamat yang mungkin sekaligus.

Satu tes simbolik dengan demikian secara konseptual setara dengan menjalankan tes
yang sama untuk *setiap* kombinasi input yang mungkin — sebuah perulangan raksasa
yang mustahil dijalankan satu per satu. Mesin eksekusi simbolik menyiasatinya:
ia mengeksekusi kode sekali sambil melacak kendala-kendala yang berlaku di tiap
cabang (misalnya "di cabang ini, jumlah harus lebih besar dari saldo"), lalu
memakai pemecah kendala (SMT solver) untuk menjawab satu pertanyaan: *adakah
kombinasi input yang memenuhi semua kendala sekaligus melanggar asersi?* Bila ada,
tool melaporkan kombinasi itu sebagai **contoh tandingan** (counterexample) —
nilai input konkret yang persis memicu pelanggaran. Bila solver menyelesaikan
pemeriksaan tanpa menemukan contoh tandingan, properti itu terbukti berlaku
untuk semua input di dalam batas model — jaminan yang tidak bisa diberikan
fuzzing berbasis sampel.

## 2. Bentuk tes simbolik

Tes simbolik disusun mirip tes fuzz, dalam empat langkah:

1. **Siapkan state awal.** Fungsi `setUp()` membuat instance kontrak target dan
   menginisialisasi state. Bedanya dengan fuzzing: state awal pun boleh dibuat
   simbolik — misalnya total suplai awal sebuah token dinyatakan sebagai simbol,
   sehingga pengujian mencakup semua konfigurasi suplai, bukan satu angka acak.
2. **Nyatakan input simbolik.** Parameter tes dideklarasikan seperti biasa, tetapi
   tiap parameter adalah simbol. Simbol juga bisa dibuat di dalam tubuh tes,
   termasuk array dinamis — yang harus dibangun dengan ukuran tetap (misalnya
   array byte sepanjang 96, atau array bilangan dengan panjang yang ditetapkan
   dulu), karena simbol tidak bisa menyatakan panjang yang tak tentu.
3. **Batasi input yang valid.** Dengan `assume`, tentukan syarat yang harus
   dipenuhi input agar relevan — contohnya penerima bukan alamat nol, atau
   pengirim punya saldo cukup. Kombinasi yang melanggar syarat ini diabaikan.
   Peringatan penting: syarat yang terlalu kuat akan mengecualikan input yang
   sebenarnya valid, sehingga bug di wilayah itu tidak pernah diperiksa.
   Untuk membatasi rentang, `assume` lebih disarankan daripada `bound`,
   karena `bound` cenderung lambat dan kurang mudah dibaca.
4. **Panggil kontrak, lalu asersi state akhir.** Bandingkan state setelah
   pemanggilan dengan yang diharapkan. Bila ada input yang melanggar asersi,
   tool melaporkan contoh tandingannya.

Satu detail penting: tool ini hanya melaporkan pelanggaran **asersi** (revert
dengan `Panic(1)`). Revert jenis lain — misalnya overflow aritmetika atau
kegagalan panggilan eksternal — diabaikan. Karena itu, bila yang ingin diuji
justru kondisi kegagalan, panggilan harus dilakukan lewat low-level call
(agar eksekusi berlanjut walau panggilan gagal dan nilai suksesnya bisa
diperiksa), atau memakai blok `unchecked` agar overflow tidak menutupi
pelanggaran asersi. Untuk compiler lama (sebelum 0.8.0) yang memakai opcode
`INVALID` untuk asersi, dibutuhkan asersi kustom yang revert dengan `Panic(1)`.

## 3. Jebakan klasik: properti yang ditulis asal-asalan

Panduan Halmos memberi contoh yang instructif: asersi sederhana "saldo pengirim
berkurang sebesar jumlah, saldo penerima bertambah sebesar jumlah" ternyata
gagal pada satu kasus — ketika pengirim dan penerima adalah **alamat yang sama**.
Transfer ke diri sendiri tidak mengubah saldo, sehingga asersi di atas tidak
terpenuhi. Contoh tandingan yang dilaporkan justru mengungkap kelemahan
*properti yang ditulis*, bukan kelemahan kontrak. Pelajarannya: menulis properti
yang benar sama sulitnya dengan menulis kode yang benar. Setiap properti harus
diuji terhadap kasus tepi: alamat nol, alamat yang sama, nilai nol, nilai
maksimum, dan kombinasi yang membuat dua variabel berimpit.

## 4. Bedanya dengan fuzzing invariant (yang sudah kami miliki)

| Aspek | Fuzzing invariant (Foundry) | Pengujian simbolik (Halmos) |
|---|---|---|
| Cara menjelajah input | Sampel acak dari ruang input | Penalaran atas seluruh ruang input sekaligus |
| Urutan panggilan | Kuat — menguji urutan panjang, state berubah dari waktu ke waktu | Lemah — umumnya satu atau sedikit panggilan per tes |
| Jaminan | Tidak ada: tidak menemukan bug ≠ tidak ada bug | Bila solver selesai tanpa contoh tandingan, properti terbukti (dalam batas model) |
| Kecepatan | Cepat, ribuan panggilan per detik | Lambat; bisa mentok pada ledakan jalur (path explosion) |
| Nilai langka | Bisa terlewat (mis. nilai persis pemicu cabang) | Ditemukan solver secara sistematis |
| Kelemahan | Melewatkan kasus tepi yang jarang | Sulit pada loop tak terbatas, hash, dan operasi non-linear |

Keduanya saling melengkapi, bukan saling menggantikan. Fuzzing menjelajah
*ruang state* (urutan interaksi); simbolik membuktikan *properti atas satu
langkah* untuk semua input. Bug logic yang hanya muncul dari urutan panjang
tetap ranah fuzzing; bug yang bersembunyi di satu nilai input yang spesifik
adalah ranah simbolik.

## 5. Menerapkan metodologi ini dengan Foundry 1.9.0 (tanpa Halmos)

Karena tool-nya tidak diinstal, yang kami ambil adalah *disiplin berpikirnya*:

1. **Tulis properti, lalu daftar kasus batasnya.** Untuk tiap properti invariant
   yang sudah ditulis di fase A, buat daftar kasus batas manual: nilai 0, 1,
   maksimum, maksimum−1, alamat nol, alamat yang sama dengan alamat lain,
   saldo tepat sama dengan jumlah, dan kombinasi dua variabel yang berimpit.
2. **Uji tiap kasus batas secara deterministik.** Tulis satu tes Foundry per
   kasus batas (bukan fuzz), sehingga tiap kasus selalu dijalankan — ini
   meniru peran solver yang "tidak melewatkan nilai langka".
3. **Periksa `assume` di tes fuzz.** Audit semua `assume`: apakah ia menyaring
   terlalu banyak input? Apakah ada input valid yang tanpa sengaja dikecualikan?
   Fuzzing dengan `assume` yang vakum memberi rasa aman palsu (lihat juga
   file `trailofbits-skills-rewrite.md` tentang properti vakum dan tautologi).
4. **Pisahkan properti "terbukti sampel" dari "terbukti menyeluruh".** Jangan
   pernah mengklaim sebuah properti terbukti hanya karena fuzzing tidak
   menemukan pelanggaran. Catat secara jujur: properti X diuji dengan N
   panggilan fuzz + M kasus batas deterministik.
5. **Gunakan contoh tandingan sebagai pola pikir.** Saat menulis properti baru,
   tanyakan: "kombinasi input apa yang akan dilaporkan solver sebagai contoh
   tandingan bila properti ini salah?" — lalu tulis tes untuk kombinasi itu
   lebih dulu.

## 6. Testabilitas

Metodologi ini dapat diuji tanpa tool: ambil kontrak lending lokal dari fase A,
terapkan langkah 1–2 di atas, dan ukur apakah ada kasus batas yang lolos dari
fuzzing invariant tetapi tertangkap oleh tes kasus batas deterministik. Bila ada,
metodologi ini terbukti menambah nilai di atas fuzzing murni. Bila tidak ada
dalam beberapa percobaan, catat itu juga — metodenya tetap berguna sebagai
disiplin, bukan sebagai penemu bug otomatis.

## 7. Batasan

- **Ledakan jalur:** tiap percabangan menggandakan jalur yang harus diperiksa;
  kontrak dengan banyak cabang atau loop dapat membuat solver tidak selesai.
- **Operasi yang sulit disimbolkan:** hash (keccak), kriptografi, dan loop
  dengan batas yang bergantung input simbolik adalah titik lemah klasik.
- **Bukan untuk urutan panjang:** pengujian simbolik umumnya satu panggilan;
  bug yang butuh 5–10 panggilan berurutan tetap harus ditemukan lewat fuzzing.
- **Hanya asersi:** revert non-asersi diabaikan kecuali tes ditulis khusus
  untuk itu (low-level call / unchecked).
- **Kualitas properti menentukan hasil:** properti yang salah memberi rasa
  aman palsu — sama seperti di fuzzing.

## 8. Sumber

- a16z/halmos — README repo (AGPL-3.0), dibaca 16 Nov 2026.
- a16z/halmos — `docs/getting-started.md`, "How to write symbolic tests with
  Halmos", dibaca penuh 16 Nov 2026.
- Postingan pengantar a16zcrypto tentang symbolic testing (dirujuk dari README).
- Catatan: lisensi AGPL-3.0 — dokumen ini adalah rumusan ulang metodologi,
  bukan adopsi atau salinan kode.
