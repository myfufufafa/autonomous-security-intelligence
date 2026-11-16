# ItyFuzz — Studi Metodologi + Audit Jalur Instalasi

**Tanggal:** 16 November 2026 (misi Skill Evolution, Pass 2 fase D)
**Sumber:** `fuzzland/ityfuzz` — "Blazing Fast Bytecode-Level Hybrid Fuzzer
for Smart Contracts" (MIT, 1.122★, 187 fork, update terakhir 12 Nov 2026,
repo TIDAK diarsip). Dokumen dibaca: README repo (penuh, via GitHub API),
skrip installer `ityfuzzup/install` + `ityfuzzup/ityfuzzup` (dibaca penuh,
TIDAK dijalankan), `Dockerfile` (dibaca penuh), daftar rilis GitHub.
**Status:** STUDI METODOLOGI SAJA. Tool TIDAK diinstal, TIDAK diunduh,
TIDAK dijalankan, kode tidak diadopsi. Semua uraian di bawah adalah rumusan
ulang dengan kata sendiri dalam Bahasa Indonesia.
**Keputusan: TUNDA** (lihat §7 — bukan tolak, bukan adopsi).

## 1. Apa itu ItyFuzz (dalam kata sendiri)

Fuzzer hybrid untuk smart contract yang bekerja di level bytecode.
"Hybrid" artinya dua mesin digabung: (a) **fuzzing** — menjalankan banyak
urutan transaksi acak/terpandu dan mengamati apa yang terjadi; (b)
**eksekusi simbolik/konkolik** — memperlakukan sebagian input sebagai
simbol, memakai solver SMT untuk menghitung nilai input yang bisa
mencapai cabang kode tertentu (misalnya syarat `if` yang jarang
terpenuhi). Hasil simbolik dipakai untuk mengarahkan fuzzer ke jalur
yang belum terjangkau. Mesin fuzzing di bawahnya adalah LibAFL
(framework fuzzing akademik). Mendukung EVM dan MoveVM; untuk kami
yang relevan hanya EVM.

Dua mode pemakaian:

- **Off-chain (mode Foundry):** menjalankan invariant test Foundry yang
  sudah kita tulis (`ityfuzz evm -m test/Invariant.sol:Invariant`),
  tapi dengan mesin hybrid di belakangnya, bukan mesin fuzz Foundry.
- **On-chain (mode fork):** mengambil kontrak yang sudah ter-deploy di
  suatu chain pada nomor blok tertentu, lalu mem-fuzz-nya di fork lokal
  — termasuk kontrak TANPA source code (ada dukungan dekompilasi).

## 2. Cara kerja (metodologi, diringkas)

1. **Pemodelan penyerang dengan dana tak terbatas.** Saat mem-fuzz,
   ItyFuzz mengasumsikan penyerang bisa meminjam berapa pun lewat
   flash loan. Ini menghilangkan hambatan modal saat menjelajah jalur
   yang butuh dana besar — jalur yang tidak akan pernah dicoba fuzzer
   biasa karena saldo penyerang terbatas.
2. **Simulasi likuidasi.** Selama fuzzing, tool mensimulasikan jual-beli
   token dari liquidity pool — artinya harga/oracle dari pool bisa
   bergerak selama kampanye, dan jalur yang bergantung pada harga yang
   sudah dimanipulasi bisa ditemukan.
3. **Eksplorasi reentrancy.** Bila ada peluang reentrancy, tool secara
   aktif mencoba memanfaatkannya untuk membuka jalur kode baru (bukan
   sekadar menandai "mungkin reentrant").
4. **Penjadwalan daya (power scheduling).** Waktu komputasi diprioritaskan
   ke bagian kode yang "lebih mungkin mengandung bug" menurut sinyal
   coverage — bukan dibagi rata.
5. **Pembuatan exploit otomatis.** Bila properti dilanggar, tool mencoba
   merangkai urutan transaksi menjadi exploit yang bisa dijalankan
   ulang — bukan sekadar melaporkan "invariant X rusak".
6. **Detektor bawaan (mode on-chain).** Untuk kontrak tanpa properti
   yang kita tulis sendiri, ada detektor bawaan: kehilangan presisi,
   overflow integer, pencurian dana, penyalahgunaan pair Uniswap, dan
   sejenisnya.

Pelajaran metodologi yang bisa dipakai TANPA tool-nya (langsung ke
Foundry 1.9.0 yang sudah dimiliki):

- **Asumsi dana tak terbatas saat menalar serangan.** Saat menulis
  handler invariant, jangan batasi modal penyerang pada saldo awal
  yang kecil — beri handler akses flash-loan-like (mint besar di
  setup) supaya jalur yang butuh modal besar tetap dijelajahi.
- **Simulasikan pergerakan harga di dalam kampanye.** Handler bisa
  memasukkan aksi "jual/beli di pool" antar panggilan, supaya invariant
  yang bergantung pada harga diuji dalam keadaan termanipulasi —
  bukan hanya pada harga awal.
- **Urutkan counterexample sebagai exploit.** Setiap urutan gagal
  hasil shrink (yang sudah dilakukan skill invariant-testing) adalah
  kandidat exploit — dokumentasikan sebagai repro yang bisa
  dijalankan ulang, bukan sekadar "test merah".

## 3. Perbandingan vs Foundry invariant testing (yang sudah dimiliki)

| Aspek | Foundry 1.9.0 (dimiliki, teruji) | ItyFuzz (dipelajari, tidak dimiliki) |
|---|---|---|
| Mesin | Fuzzing acak terpandu handler | Hybrid: fuzzing + konkolik/SMT (LibAFL) |
| Properti | `invariant_*` yang kita tulis | Sama (mode Foundry) + detektor bawaan (mode on-chain) |
| Flash loan | Harus dimodelkan manual di handler | Disimulasikan bawaan (dana tak terbatas) |
| Likuidasi / harga | Harus dimodelkan manual | Disimulasikan bawaan |
| Fork on-chain | Bisa (via RPC publik) tapi manual | Bawaan, di blok mana pun |
| Tanpa source code | Tidak bisa | Bisa (dekompilasi) |
| Pembuatan exploit | Manual (shrink urutan gagal) | Otomatis |
| Biaya / instal | Sudah ada, 0 | Berat (lihat §5) |
| Bukti kerja di tangan kami | Teruji: 51.200 panggilan lulus, versi buggy tertangkap; 6/13 DVD | Belum ada bukti kerja sendiri |

Kesimpulan perbandingan: ItyFuzz MENAMBAH kemampuan (bukan mengganti).
Yang tidak digantikannya: **pemodelan invariant oleh manusia**.
Di mode Foundry ia tetap menjalankan properti YANG KITA TULIS — jadi
kualitas hasil tetap dibatasi kualitas invariant kita. Di mode on-chain
ia hanya menangkap kelas bug yang dikenali detektor bawaannya —
logic/business-logic yang butuh pemahaman protokol tetap butuh
invariant manual. Disiplin "namai invariant dulu" dari skill
invariant-testing tetap menjadi fondasi.

## 4. Klaim kinerja vendor — status verifikasi

Semua klaim di bawah ini berasal dari README/docs vendor. **Tidak satu
pun sudah kami reproduksi secara independen.** Dicatat apa adanya dengan
statusnya:

- **"126 kerentanan ditemukan, Echidna 0, Mythril 9"** (pada proyek
  besar dunia nyata). Sumber yang dirujuk vendor: halaman backtesting
  mereka + makalah riset (ACM, DOI 10.1145/3597926.3598059 — venue
  peer-review). Makalah peer-review memberi bobot pada klaimnya, tapi
  angka "126 vs 0" adalah hasil backtesting VENDOR SENDIRI, bukan
  reproduksi independen kami. Status: **TIDAK TERVERIFIKASI** oleh kami.
- **Benchmark Daedaluzz (ConsenSys):** ItyFuzz tanpa eksekusi simbolik
  menemukan 44% lebih banyak bug dari Echidna dan 31% lebih banyak
  dari Foundry; 2,5x lebih cepat dari Echidna, 1,5x dari Foundry.
  Benchmark-nya milik pihak ketiga (ConsenSys), tapi angka yang
  dikutip tetap dari vendor. Status: **TIDAK TERVERIFIKASI** oleh kami.
- **"Exploit otomatis untuk >80% hack sebelumnya, tanpa tahu hack-nya."**
  Dirujuk ke halaman backtesting. Status: **TIDAK TERVERIFIKASI** oleh kami.
- **Bug baru yang ditemukan vendor** (dicatat di README): BSC $rats NFT
  (overflow → mint tak terbatas, $79 ribu), 9419 Token (manipulasi
  harga, $35 ribu), dan 5 kasus lain ($4–19 ribu). Ini adalah klaim
  temuan, bukan bukti yang bisa kami cek ulang dari README saja.

Catatan: keberadaan makalah peer-review + benchmark pihak ketiga membuat
klaim ini LEBIH dari sekadar marketing, tapi tetap bukan bukti kerja
di tangan kami. Cara yang benar untuk memverifikasi: jalankan tool
terhadap korpus yang SUDAH kami ketahui jawabannya (3 insiden
DeFiHackLabs yang sudah kami replay: Euler, UwU, KyberSwap) dan bandingkan
apa yang ditemukan vs Foundry. Itu belum dilakukan — dan tidak bisa
dilakukan tanpa instalasi, yang ditunda (lihat §7).

## 5. Audit jalur instalasi (dibaca, TIDAK dijalankan)

### 5.1 Jalur default — DILARANG aturan kami

```bash
curl -L https://ity.fuzz.land/ | bash
ityfuzzup
```

- `curl | bash` adalah pola yang DILARANG keras oleh aturan misi
  (eksekusi kode remote tanpa audit). Situs `ity.fuzz.land` menyajikan
  skrip `ityfuzzup/install` yang: mengunduh biner `ityfuzzup` dari
  `raw.githubusercontent.com/fuzzland/ityfuzz/master/ityfuzzup/ityfuzzup`,
  menyimpannya ke `~/.ityfuzz/bin/`, dan **menulis ke file profil shell**
  (`.bashrc` / `.zshenv` / `config.fish`) untuk menambah PATH.
- Skrip `ityfuzzup` sendiri kemudian (berdasarkan isi yang dibaca):
  menerima opsi `--repo/--branch/--version/--pr/--commit/--path` dan
  membangun/mengunduh biner dari repo. Artinya jalur default ini
  mengeksekusi kode yang diunduh dari internet TANPA verifikasi checksum
  yang terlihat di skrip yang dibaca.
- **Verdict jalur ini: TIDAK BOLEH dipakai.** Bukan karena vendornya
  jahat — tapi karena polanya melanggar aturan keamanan kami dan tidak
  ada verifikasi integritas yang bisa kami audit sebelumnya.

### 5.2 Jalur build-from-source — ADA, tapi berat

`Dockerfile` repo menunjukkan build yang sah:

- Base: `rust:buster`; dependensi sistem: `clang`, `cmake`,
  `pkg-config`, `libz3-dev`, `libssl-dev`, `git`.
- Build: `cargo build --release` dengan feature flags, antara lain
  `cmp dataflow evm print_txn_corpus full_trace force_cache
  real_balance` (off-chain) dan varian on-chain/print-logs.
- Ini jalur yang PALING bisa diaudit (source terbuka, `Cargo.lock`
  ada) — tapi: butuh toolchain Rust + Z3 (belum ada di sandbox),
  waktu compile lama (proyek Rust besar), dan tetap butuh audit
  `Cargo.toml` + build script sebelum build. Belum dilakukan.

### 5.3 Biner prebuilt (rilis GitHub) — ADA, tapi basi + tak bertanda

- Rilis `nightly-*` menyediakan `ityfuzz_nightly_linux_amd64.tar.gz`
  (dan varian darwin/arm64 pada rilis lama).
- **Rilis terbaru: 22 Mei 2025** — padahal repo di-update 12 Nov 2026.
  Biner rilis tertinggal ~6 bulan dari source. Tidak ada checksum /
  tanda tangan yang terlihat pada halaman rilis yang dibaca.
- **Verdict: tidak direkomendasikan.** Biner basi + tanpa verifikasi
  integritas = tidak memenuhi standar adopsi kami.

### 5.4 Kebutuhan kunci API (mode on-chain)

Contoh di README memakai `ETH_RPC_URL` + **kunci API Etherscan**
(dan kunci contoh tertulis di README vendor — kunci itu MILIK VENDOR,
bukan milik kami, dan TIDAK kami salin/pakai). Mode on-chain butuh RPC
+ kunci Etherscan sendiri. Aturan kami: RPC hanya publik tanpa kunci;
kunci API pribadi tidak dipakai untuk fuzzing. Ini membatasi mode
on-chain bila suatu hari dipertimbangkan.

## 6. Risiko yang dicatat

- **Rantai pasok:** installer remote tanpa checksum; biner nightly
  tanpa tanda tangan; dependensi Rust (crates) belum diaudit.
- **Kedaluwarsa:** rilis biner tertinggal 6 bulan dari source — bug
  yang sudah diperbaiki di source belum tentu ada di biner.
- **Overclaim:** angka kinerja vendor belum direproduksi; mengadopsi
  atas dasar klaim README melanggar prinsip "bukti sebelum asumsi".
- **Biaya belajar:** tool besar (Rust, Z3, LibAFL) — waktu setup dan
  pemeliharaan tidak sebanding bila manfaatnya belum terbukti pada
  kasus nyata kami.
- **False sense of security:** detektor bawaan hanya menangkap kelas
  yang dikenalinya; logic bug yang menjadi fokus misi ini tetap butuh
  invariant manual — tool ini tidak memecahkan masalah itu.

## 7. Keputusan: TUNDA (bukan tolak, bukan adopsi)

**Rekomendasi: TUNDA adopsi ItyFuzz.**

Alasan:

1. Jalur instalasi default dilarang aturan kami; jalur yang sah
   (build-from-source) berat dan belum diaudit.
2. Manfaat marginal di atas Foundry invariant testing BELUM TERBUKTI
   pada kasus kami — bottleneck kami adalah menemukan logic bug di
   program berscope, bukan throughput fuzzing.
3. Klaim kinerja vendor belum direproduksi secara independen.
4. Nilai uniknya (fork on-chain, exploit otomatis, dekompilasi)
   paling relevan untuk audit kontrak live tanpa source — BUKAN mode
   kerja kami saat ini (PoC EVM lokal pada program berscope).

**Syarat untuk dipertimbangkan kembali (salah satu):**

- (a) Ada bounty/Program konkret di mana fuzzing fork on-chain atau
  pembuatan exploit otomatis menjadi faktor penentu — bukan sekadar
  "bagus untuk dimiliki".
- (b) Build-from-source dilakukan di sandbox sekali pakai dengan audit
  penuh (`Cargo.toml`, `Cargo.lock`, build script) + verifikasi main
  chat — dan build BERHASIL direproduksi dari source.
- (c) Uji deteksi pada korpus yang sudah diketahui jawabannya (3
  insiden DeFiHackLabs: Euler, UwU, KyberSwap) — bandingkan apa yang
  ditemukan ItyFuzz vs Foundry invariant testing. Bila ItyFuzz
  menemukan sesuatu yang Foundry lewatkan, itu bukti nyata.

**Yang langsung dipakai dari studi ini (tanpa tool):** tiga disiplin
metodologi §2 — asumsi dana tak terbatas di handler, simulasi
pergerakan harga antar panggilan, dan dokumentasi counterexample
sebagai exploit yang bisa dijalankan ulang. Ketiganya bisa masuk ke
skill `invariant-testing` / `bounty-hunter` pada revisi berikut.

## 8. Referensi

- Repo: https://github.com/fuzzland/ityfuzz (MIT, 1.122★, 187 fork,
  update 12 Nov 2026)
- Docs: https://docs.ityfuzz.rs (gagal dibuka saat studi — dicatat,
  bukan dijadikan sumber)
- Makalah: ACM DOI 10.1145/3597926.3598059 (dirujuk vendor; belum dibaca
  penuh)
- Backtesting vendor: https://docs.ityfuzz.rs/tutorials/exp-known-working-hacks
  (dirujuk vendor; belum direproduksi)
- File yang dibaca: README (GitHub API), `ityfuzzup/install`,
  `ityfuzzup/ityfuzzup`, `Dockerfile`, daftar rilis — 16 Nov 2026.
  TIDAK ADA file yang diunduh/dijalankan.
