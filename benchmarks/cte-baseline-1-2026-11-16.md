# Baseline Capture The Ether — Batch 1 (Lotteries + Math, 9 tantangan)

**Tanggal:** 16 November 2026 (misi Skill Evolution, Pass 2 fase L)
**Status:** SELESAI 9/9 — verifikasi segar `forge test` di `/tmp/cte-work`:
**18 tests passed, 0 failed** (9× `testInit` + 9× `testSolve`, semua
menegaskan `isComplete() == true` setelah exploit).
**Skor: 9/9. Severity: 0 Critical, 2 High, 5 Medium, 2 Low.**
Gas testSolve total: **1.893.904**.

## §1 Setup — sumber kontrak + catatan kejujuran sumber

**Repo resmi asli HILANG.** `github.com/smarx/capture-the-ether` dan
`github.com/OpenZeppelin/capture-the-ether` keduanya 404 (dicek via
`gh api`, 16 Nov 2026). `github.com/capturetheether/capture-the-ether`
juga tidak ditemukan di hasil pencarian GitHub. Yang dipakai:

| Tantangan | Sumber kontrak | Versi |
|---|---|---|
| Guess the secret number, Guess the random number, Guess the new number, Predict the future, Token sale, Token whale, Retirement fund | `RareSkills/capture-the-ether-foundry` (recreation Foundry) — hanya `src/` | Solidity 0.8.13, `unchecked` eksplisit untuk melestarikan kerentanan 0.4 |
| Guess the number | `0xraion/capture-the-ether-solutions-foundry`, `src/lotteries/challenges/GuessTheNumberChallenge.sol` (SPDX MIT) | Solidity 0.8.0 |
| Mapping | Kontrak 0.4.21 ASLI (`MrToph/capture-the-ether`, `contracts/math/Mapping.sol`; identik dengan `0xraion/.../MappingChallenge.sol`) | Solidity 0.4.21, dikompilasi Foundry via `deployCode` |

**Lisensi:** repo RareSkills TIDAK mendeklarasikan lisensi
(`UNLICENSED` di file, tanpa LICENSE di repo); raion GuessTheNumber
ber-SPDX MIT. Yang dilakukan di sini hanya MEMBACA kontrak tantangan
dan menulis PoC sendiri — TIDAK ada kode yang diadopsi. Kontrak asli
CTE dipublikasikan terbuka di capturetheether.com oleh smarx.

**Kontaminasi: NOL.** File `test/` di semua repo mirror TIDAK PERNAH
dibuka (berisi solusi orang lain). Yang dibaca hanya file `src/`
kontrak tantangan. File `src/` RareSkills memang berisi stub
`ExploitContract` KOSONG (fungsi yang mengembalikan nilai default) —
stub itu TIDAK dipakai; semua attacker contract ditulis sendiri dari
nol. Satu-satunya pengecualian: tidak ada.

**Koreksi terhadap brief tugas: "Token balance" TIDAK ADA di daftar
resmi CTE.** Daftar Math resmi di capturetheether.com/challenges
(dibaca 16 Nov 2026): Token sale, **Token whale**, Retirement fund,
Mapping, Donation, Fifty years. Tidak ada tantangan bernama "Token
balance" di kategori mana pun. Yang dikerjakan sebagai pengganti
adalah **Token whale** (tantangan Math resmi yang paling dekat —
keduanya soal saldo token; Token whale adalah tantangan klasik yang
dimaksud). Dicatat jujur di sini agar tidak diklaim sebagai "Token
balance".

**Setup proyek:** `/tmp/cte-work` (Foundry 1.9.0, `forge-std` disalin
dari `/tmp/ethernaut-work/lib/`). Kontrak 0.4.21 (Mapping) dikompilasi
Foundry otomatis (solc 0.4.x diunduh) dan di-deploy via `deployCode`
— pola yang sama dengan level 0.6 di Ethernaut fase G. Solusi disalin
ke `benchmarks/` SEGERA setelah tiap level lolos (pelajaran fase F);
kesembilan file solusi terverifikasi IDENTIK (`cmp`) dengan file test
yang lolos.

**Kegagalan harness (bukan logika): 3.** Run pertama: testSolve
#1/#2/#3 GAGAL karena test contract tidak punya `receive()` sehingga
`transfer`/`call` 2 ether dari kontrak tantangan revert ("Failed to
Send 2 ether" / "Fail to send to msg.sender"). Perbaikan: tambah
`receive() external payable {}` ke tiga test contract. Run kedua:
18/18 PASS. Tidak ada kegagalan logika.

## §2 #1 Guess the number (200 poin) — Low, gas 43.729, ~2 menit

**Kontrak:** `GuessTheNumberChallenge` (0.8.0): `uint8 answer = 42`
(hardcoded, tanpa visibilitas = internal), `guess(n)` bayar 1 ether,
bila benar kirim 2 ether. `isComplete`: saldo kontrak 0.

**Root cause:** "rahasia" yang disimpan sebagai state variable
biasa tetap TERBACA dari storage — slot 0 berisi 42. Tidak ada
rahasia on-chain.

**PoC:** `vm.load(address(challenge), bytes32(0))` -> 42 ->
`guess{value: 1 ether}(42)` -> terima 2 ether -> saldo 0.

**Severity: Low** (di konteks CTF ini warmup; sebagai primitif
lotre produksi, jawaban hardcoded yang terbaca dari storage adalah
Critical — lotre tidak pernah bisa mengandalkan rahasia on-chain).

**Baru vs DVD/Ethernaut:** TIDAK BARU — varian dari Ethernaut #8
Vault (`private` terbaca dari storage). Bedanya: di sini jawabannya
bahkan bukan `private`, melainkan nilai hardcoded yang dibaca dari
slot 0.

## §3 #2 Guess the secret number (300 poin) — Low, gas 78.008, ~3 menit

**Kontrak:** `GuessTheSecretNumber` (0.8.13): `bytes32 answerHash`
(slot 0) = keccak256 dari jawaban uint8. `guess(n)` bayar 1 ether,
bila `keccak256(n) == answerHash` kirim 2 ether.

**Root cause:** ruang jawaban hanya 256 nilai. Hash-nya publik
(storage slot 0), jadi 256 kandidat bisa diuji off-chain tanpa
memanggil `guess` satu kali pun — tidak ada biaya tebakan yang salah.

**PoC:** baca `answerHash` via `vm.load` slot 0; loop i = 0..255,
`keccak256(abi.encodePacked(uint8(i))) == answerHash` -> ketemu n;
`guess{value: 1 ether}(n)` sekali -> 2 ether -> saldo 0.

**Severity: Low** (kelas yang sama dengan #1; kekuatan "rahasia"
hanya 8 bit. Di produksi, secret 8-bit yang di-hash = bukan rahasia).

**Baru vs DVD/Ethernaut:** VARIAN BARU — brute-force hash ruang
kecil (256) sebagai vektor serangan. Ethernaut tidak punya tantangan
brute-force hash; pola ini melengkapi P-06 fase J (storage terbaca):
bukan hanya membaca nilai, tapi membalik hash lewat enumerasi ruang
kecil.

## §4 #3 Guess the random number (300 poin) — Medium, gas 43.515, ~3 menit

**Kontrak:** `GuessRandomNumber` (0.8.13): jawaban dihitung di
CONSTRUCTOR dari `keccak256(blockhash(block.number-1),
block.timestamp)`.

**Root cause:** "randomness" dari dua nilai publik yang bisa
dihitung ulang siapa pun — dan nilainya TETAP sejak deployment
(dihitung sekali di constructor).

**PoC:** di test (blok yang sama dengan deployment), hitung rumus
yang sama -> jawaban -> `guess{value: 1 ether}(jawaban)` -> 2 ether.

**Severity: Medium** (di produksi, lotre dengan randomness
blockhash+timestamp = High/Critical — penambang/validator bisa
mempengaruhi keduanya; di sini Medium karena tantangannya memang
lotre CTF).

**Baru vs DVD/Ethernaut:** TIDAK BARU — Ethernaut #3 CoinFlip
(blockhash sebagai randomness). Varian: jawaban dihitung di
constructor (bukan per panggilan), sehingga cukup dihitung sekali.

## §5 #4 Guess the new number (400 poin) — Medium, gas 55.419, ~4 menit

**Kontrak:** `GuessNewNumber` (0.8.13): jawaban dihitung di SAAT
`guess()` dipanggil, dari `blockhash(block.number-1)` +
`block.timestamp` blok yang sama.

**Root cause:** sama dengan #3, tapi jawaban dihitung per panggilan
— jadi harus dihitung DALAM transaksi yang sama dengan tebakan.
Attacker contract menghitung jawaban dari data blok yang sama lalu
memanggil `guess` dalam satu transaksi.

**PoC:** attacker contract: `answer =
uint8(keccak256(blockhash(block.number-1), block.timestamp))` lalu
`target.guess{value: 1 ether}(answer)` -> 2 ether.

**Severity: Medium** (kelas yang sama dengan #3; versi yang lebih
"benar" secara desain — tetap bisa diprediksi karena inputnya publik
di blok yang sama).

**Baru vs DVD/Ethernaut:** VARIAN — randomness per-panggilan yang
harus dihitung on-chain di transaksi yang sama (bukan off-chain).
Pola "hitung di blok yang sama" adalah versi on-chain dari CoinFlip.

## §6 #5 Predict the future (500 poin) — Medium, gas 209.470, ~6 menit

**Kontrak:** `PredictTheFuture` (0.8.13): `lockInGuess(n)` (1 ether,
`settlementBlockNumber = block.number + 1`); `settle()` (hanya
guesser, `block.number > settlementBlockNumber`) menghitung jawaban
`= keccak256(blockhash(block.number-1), block.timestamp) % 10`;
`guesser = address(0)` DULU, baru bila tebakan benar kirim 2 ether.

**Root cause:** (a) jawaban settle dihitung dari data blok saat
settle — bisa dihitung SEBELUM memanggil settle di blok yang sama;
(b) tebakan yang salah TIDAK menghukum: `guesser` di-reset sehingga
bisa lock lagi, dan tebakan yang sudah terkunci bisa "ditunggu" —
cukup tunggu blok yang jawabannya == tebakan, baru settle.

**PoC:** attacker lock tebakan 0; loop: `vm.roll(block.number + 1)`,
hitung jawaban blok saat itu; bila == 0, panggil `settle()` -> 2
ether. Rata-rata ~10 blok tunggu (peluang 1/10 per blok).

**Severity: Medium** (randomness yang bisa diprediksi + mekanisme
retry gratis. Di produksi, lotre "tebak angka masa depan" dengan
settlement yang bisa dipilih waktunya = High — penyerang hanya
mengeksekusi saat menang).

**Baru vs DVD/Ethernaut:** BARU — pola "tunggu blok yang
menguntungkan" (retry-until-match): bukan memprediksi jawaban untuk
blok tertentu, melainkan memilih WAKTU eksekusi berdasarkan jawaban
yang sudah bisa dihitung. Tidak ada padanannya di DVD/Ethernaut.

## §7 #6 Token sale (500 poin) — High, gas 98.684, ~5 menit

**Kontrak:** `TokenSale` (0.8.13): `PRICE_PER_TOKEN = 1 ether`;
`buy(numTokens)` menghitung `total = numTokens * PRICE_PER_TOKEN`
dalam `unchecked`, lalu `require(msg.value == total)`;
`sell(numTokens)` membayar `numTokens * PRICE_PER_TOKEN` (checked,
0.8 — overflow di sini akan revert, jadi jual harus dalam jumlah
kecil).

**Root cause:** perkalian harga dalam `unchecked` bisa overflow ke
angka kecil. `numTokens = ceil(2^256 / 1e18)` =
115792089237316195423570985008687907853269984665640564039458 ->
`total = 415992086870360064` wei (~0,416 ether) untuk ~1,16e59
token. Beli murah, jual 1 token -> terima 1 ether -> saldo kontrak
0 -> `isComplete` (`balance < 1 ether`).

**PoC:** `buy{value: 415992086870360064}(115792089237316195423570985008687907853269984665640564039458)`;
`assertEq(total, 415992086870360064)`; `sell(1)` -> 1 ether.

**Severity: High** (di produksi: pencurian dana penuh lewat
overflow harga — kelas Critical bila kontrak memegang dana besar;
di sini High karena dana kontrak hanya 1 ether dan tantangannya
memang mendemonstrasikan overflow).

**Baru vs DVD/Ethernaut:** VARIAN — Ethernaut #5 Token (underflow
saldo pra-0.8). Yang baru: overflow PERKALIAN HARGA di `buy` dengan
perhitungan wei eksak (2^256 mod 1e18 = 584007913129639936), plus
asimetri checked/unchecked: `buy` unchecked (bisa overflow) tapi
`sell` checked (harus jual dalam jumlah kecil) — PoC harus memahami
keduanya.

## §8 #7 Token whale (500 poin) — High, gas 1.209.922, ~6 menit

**Kontrak:** `TokenWhale` (0.8.13): `balanceOf[player] = 1000`;
`isComplete`: `balanceOf[player] >= 1000000`. `_transfer(to, value)`
melakukan `unchecked { balanceOf[msg.sender] -= value;
balanceOf[to] += value; }`. `transferFrom(from, to, value)` memeriksa
`balanceOf[from] >= value`, `allowance[from][msg.sender] >= value`,
lalu `allowance -= value` dan memanggil `_transfer(to, value)`.

**Root cause:** CONFUSED DEPUTY — `_transfer` mendebit
`msg.sender`, BUKAN `from`. `transferFrom(player, player, v)` lolos
semua cek (saldo player >= v, allowance >= v), tapi yang didebit
adalah CALLER (saldo 0 -> underflow unchecked -> astronomis) dan
yang dikredit adalah player (+v). Dengan v = saldo player saat itu,
saldo player BERLIPAT GANDA tiap iterasi: 1000 -> 2000 -> ... ->
1.024.000 dalam 10 iterasi (tiap iterasi butuh approve ulang dari
player sebesar saldo saat itu).

**PoC:** player `0xBEEF`; attacker contract; loop <= 20x:
`vm.prank(player); approve(attacker, balanceOf(player))`;
`attacker.transferFrom(player, player, balanceOf(player))` ->
`balanceOf(player) >= 1000000`.

**Severity: High** (di produksi: penciptaan saldo dari ketiadaan
lewat allowance kecil — siapa pun yang diberi allowance sekecil
apa pun bisa menggandakan saldo target tanpa batas; kelas Critical
bila token punya nilai pasar).

**Baru vs DVD/Ethernaut:** BARU — pola confused deputy
`msg.sender` vs `from` di fungsi transfer internal + allowance
sebagai "izin mencetak saldo". Tidak ada padanannya di DVD (13/13)
maupun Ethernaut (30/30): di sana underflow selalu soal saldo
sendiri (Token #5) atau mint (Rewarder #5), bukan debit akun yang
salah lewat `transferFrom`.

## §9 #8 Retirement fund (500 poin) — Medium, gas 79.890, ~4 menit

**Kontrak:** `RetirementFund` (0.8.13): constructor(player)
menyimpan 1 ether, `owner = msg.sender` (deployer),
`beneficiary = player`, `expiration = +520 minggu`.
`withdraw()` (hanya owner): bila lebih awal, kirim 90% saldo ke
owner (penalti 10% tertinggal). `collectPenalty()` (hanya
beneficiary): `withdrawn = startBalance - balance` (unchecked),
`require(withdrawn > 0)`, lalu kirim SELURUH sisa saldo ke
beneficiary.

**Root cause:** "penalti" bukan 10% — `collectPenalty` mengirim
seluruh sisa saldo (10%) ke beneficiary. Owner + beneficiary yang
berkolusi menguras dana penuh: owner tarik 90% lebih awal,
beneficiary klaim 10% sisanya. Tidak ada pemisahan antara "dana
penalti" dan "dana yang bisa diklaim beneficiary" — dan tidak ada
yang mencegah owner dan beneficiary adalah pihak yang sama/berkolusi.

**PoC:** test contract = owner (deployer), attacker contract =
beneficiary. `withdraw()` -> 0,9 ether keluar, sisa 0,1 ether.
`attacker.collect()` -> `collectPenalty()` -> 0,1 ether keluar ->
saldo 0.

**Severity: Medium** (cacat desain ekonomi dua-peran, bukan bug
aritmetika: `withdrawn` dihitung benar, `require` benar — yang salah
adalah `collectPenalty` membayar seluruh sisa saldo sebagai
"penalti". Di produksi: dana pensiun bisa dikuras penuh oleh kolusi
owner-beneficiary; sebagai temuan audit ini High bila dana besar —
di sini Medium karena mekanismenya memang begitu didesain sebagai
teka-teki).

**Baru vs DVD/Ethernaut:** BARU (varian) — cacat desain kolusi
dua-peran + "penalti = seluruh sisa saldo". Tidak ada padanan
langsung; yang terdekat adalah pola akuntansi satu sisi (C-01 fase
K) — di sini bukan akuntansi yang salah, melainkan SEMANTIK klaim
yang salah: penalti seharusnya 10%, yang dibayar 100% dari sisa.

## §10 #9 Mapping (750 poin) — Medium, gas 75.267, ~5 menit

**Kontrak:** `MappingChallenge` (0.4.21 ASLI): `bool public
isComplete` (slot 0), `uint256[] map` (slot 1, data di
keccak256(1)). `set(key, value)`: bila `map.length <= key`,
`map.length = key + 1`, lalu `map[key] = value`. `get(key)` membaca
`map[key]`. TIDAK ADA fungsi yang pernah menyetel `isComplete =
true`.

**Root cause:** penulisan array dinamis memakai aritmetika slot:
`map[key]` berada di slot `keccak256(1) + key` (mod 2^256).
Dengan `key = 2^256 - keccak256(1)`, tulisan mendarat di slot 0 —
tepat di `isComplete`. `map.length = key + 1` hanya menulis slot 1
(panjang array), tidak menghalangi. Satu panggilan `set` menulis
variabel state yang tidak pernah dimaksudkan untuk ditulis lewat
fungsi itu.

**PoC:** `deployCode("MappingChallenge.sol:MappingChallenge")`;
`key = type(uint256).max - keccak256(abi.encodePacked(uint256(1))) + 1`;
`set(key, 1)` -> `isComplete() == true`.

**Severity: Medium** (di konteks CTF; sebagai kelas kerentanan —
penulisan storage arbitrer lewat indeks array — ini Critical di
produksi: satu panggilan fungsi bisa menimpa owner, paused, atau
saldo siapa pun bila layout-nya diketahui).

**Baru vs DVD/Ethernaut:** BARU — penulisan slot arbitrer lewat
OVERFLOW INDEKS ARRAY (bukan underflow panjang array). Ethernaut
#25 AlienCodex memakai `retract()` underflow panjang array
(0.5) lalu `revise()` menulis slot 0 — mekanismenya MIRIP (tulis
slot 0 lewat array), tapi jalurnya berbeda: di sini panjang array
diperbesar secara LEGAL (`map.length = key + 1`) dan indeks yang
dipilih membuat `keccak256(slot) + key` membungkus ke 0. Ini
melengkapi pola storage-layout (P-06 fase J): bukan hanya MEMBACA
slot, tapi MENULIS slot arbitrer lewat aritmetika indeks.

## §11 Ringkasan

| # | Tantangan | Poin | Gas testSolve | Severity | Root cause (1 baris) |
|---|---|---|---|---|---|
| 1 | Guess the number | 200 | 43.729 | Low | jawaban hardcoded 42 terbaca dari storage slot 0 |
| 2 | Guess the secret number | 300 | 78.008 | Low | hash jawaban 8-bit, brute-force 256 nilai off-chain |
| 3 | Guess the random number | 300 | 43.515 | Medium | jawaban constructor dari blockhash + timestamp publik |
| 4 | Guess the new number | 400 | 55.419 | Medium | jawaban per-panggilan dari data blok yang sama |
| 5 | Predict the future | 500 | 209.470 | Medium | jawaban settle bisa dihitung dulu; tunggu blok yang cocok |
| 6 | Token sale | 500 | 98.684 | High | overflow perkalian harga dalam `unchecked` |
| 7 | Token whale | 500 | 1.209.922 | High | `_transfer` debit `msg.sender` bukan `from` (confused deputy) |
| 8 | Retirement fund | 500 | 79.890 | Medium | penalti = seluruh sisa saldo; kolusi owner-beneficiary |
| 9 | Mapping | 750 | 75.267 | Medium | indeks array membungkus -> tulis slot 0 (`isComplete`) |

**Skor: 9/9. 0 Critical, 2 High, 5 Medium, 2 Low. Gas total
1.893.904. Semua root cause benar percobaan pertama (logika), 0
false positive logika. 3 kegagalan harness (test contract tanpa
`receive()`), bukan logika.**

**Catatan kejujuran:**
- Level 1–9 MURNI — tidak ada file `test/` repo mirror yang dibuka;
  tidak ada writeup/blog yang dibaca. Semua root cause dari membaca
  kontrak tantangan (`src/`) saja. Stub `ExploitContract` kosong di
  file `src/` RareSkills tidak dipakai.
- "Token balance" dalam brief TIDAK ADA di daftar resmi CTE —
  diganti Token whale (dicatat di §1).
- Repo resmi asli CTE hilang (404); kontrak dari recreation/mirror —
  dicatat di §1 dengan versi dan lisensi masing-masing.
- Severity di atas adalah penilaian kelas kerentanan di konteks CTF;
  beberapa kelas (randomness, overflow, storage write arbitrer)
  adalah Critical bila muncul di kontrak produksi yang memegang dana.

**Pola BARU vs DVD + Ethernaut (4):**
1. Confused deputy `_transfer` (Token whale) — debit akun yang salah
   lewat `transferFrom` + allowance sebagai izin mencetak saldo.
2. Tulis slot arbitrer lewat overflow indeks array (Mapping) —
   panjang array diperbesar legal, indeks membungkus ke slot 0.
3. Tunggu blok yang menguntungkan / retry-until-match (Predict the
   future) — memilih WAKTU eksekusi berdasarkan jawaban yang sudah
   bisa dihitung.
4. Penalti = seluruh sisa saldo + kolusi dua-peran (Retirement fund).

**Pola DIKENAL, varian baru (5):** brute-force hash ruang kecil
(Guess secret number); randomness per-panggilan on-chain (Guess new
number); overflow perkalian harga + asimetri checked/unchecked
buy-vs-sell (Token sale); jawaban hardcoded di storage (Guess the
number — varian Vault #8); jawaban constructor yang tetap (Guess
random number — varian CoinFlip #3).

**Pelajaran untuk perburuan bounty nyata:**
- `_transfer`-style internal yang memakai `msg.sender` padahal
  dipanggil dari `transferFrom` adalah pola confused deputy yang
  harus selalu diperiksa: siapa yang SEBENARNYA didebit?
- Fungsi `set` pada array dinamis + slot layout = permukaan tulis
  arbitrer: hitung `keccak256(slot) + key` untuk SEMUA fungsi yang
  menulis array dengan indeks dari pengguna.
- Lotre/prediksi apa pun yang jawabannya bisa dihitung SEBELUM
  eksekusi (blockhash, timestamp, hash ruang kecil) bukan lotre —
  dan mekanisme retry/reset membuat penyerang bisa menunggu blok
  yang menang.
- Periksa asimetri checked/unchecked: satu jalur overflow + satu
  jalur checked = PoC harus memakai keduanya secara berurutan.
- "Penalti"/"klaim" yang membayar seluruh sisa saldo adalah
  pencairan penuh dengan nama lain — baca SEMANTIK pembayaran, bukan
  hanya aritmetikanya.

## Langkah berikut

1. Batch 2 CTE: Lotteries (Predict the block hash) + Math (Donation,
   Fifty years) + Miscellaneous (Assume ownership, Token bank) —
   5 tantangan tersisa dari daftar resmi (total CTE 20 tantangan:
   3 warmup + 6 lotteries + 6 math + 2 misc; warmup dilewati karena
   bukan tantangan keamanan).
2. Integrasikan 4 pola baru (confused deputy transfer, tulis slot
   via indeks array, retry-until-match, penalti = sisa saldo) ke
   skill `bounty-hunter` / `sc-audit` / `invariant-testing` pada
   proposal integrasi berikut.
