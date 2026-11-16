# Ethernaut — Baseline (Level 11–20)

**Misi:** Autonomous Bounty Intelligence & Skill Evolution — Pass 2 fase H
**Tanggal:** 16 November 2026
**Sumber:** https://github.com/OpenZeppelin/ethernaut (MIT, clone `--depth 1`
ke `/tmp/ethernaut-baseline`, HEAD `d05643a`, 19 Nov 2025)
**Status:** Level 11–20 SELESAI — skor 10/10. Verifikasi segar: `forge test`
di proyek minimal `/tmp/ethernaut-work`: **40 tests passed, 0 failed**
(20× `testInit` + 20× `testSolve`, level 1–20; semua `testSolve`
menegaskan `factory.validateInstance(...) == true`).
**Lokasi kerja:** proyek minimal `/tmp/ethernaut-work` (sama dengan fase G,
ditambah 20 file level 11–20 + `src/helpers/UpgradeableProxy-08.sol`).
Semua solusi yang lolos disalin SEGERA ke repo ini:
`benchmarks/ethernaut-<nama>-solution.t.sol` (10 file baru; total 20).

## 1. Setup proyek — hasil uji

| Aspek | Hasil |
|---|---|
| Proyek fase G dipakai ulang | `/tmp/ethernaut-work` sudah berisi 20 file level 1–10 + lib vendored (forge-std, OZ-06, OZ-08). Tambah 20 file level 11–20 (10 kontrak + 10 factory) + helper proxy. Build: **OK** (~2 detik, solc 0.6.12 + 0.8.30). |
| PuzzleWallet import helper | `PuzzleWallet.sol` meng-import `../helpers/UpgradeableProxy-08.sol` → disalin ke `src/helpers/` (import OZ-08 Proxy + Address, tersedia di lib). |
| Motorbike (<0.7.0) | Satu-satunya level 0.6 di batch ini. Pola fase G dipakai lagi: interface + `deployCode("MotorbikeFactory.sol:MotorbikeFactory")` dari test 0.8. |
| 9 level lain | Semua `^0.8.0` — import langsung ke test 0.8 seperti biasa. |
| RPC / fork | Tidak dibutuhkan — semua level berjalan lokal (tanpa fork). |
| Foundry | 1.9.0 — kompatibel. Seluruh suite 40 test berjalan ~51 ms (plus ~2 detik compile). |

**Pola harness (sama dengan fase G):** tiap file test men-deploy factory
langsung, memanggil `factory.createInstance(player)`, menjalankan exploit,
lalu menegaskan `factory.validateInstance(...) == true`. Tidak memakai
kontrak `Ethernaut.sol` / `Utils` repo.

## 2. Level #11 — Dex

**Deskripsi:** DEX sederhana dengan 2 token; tujuan: saldo salah satu token
di pool = 0 (awal: pool 100/100, player 10/10).

**Kontrak yang dibaca:** `Dex.sol` (60 baris), `DexFactory.sol`
(validasi: `balanceOf(token1) == 0 || balanceOf(token2) == 0`).

### Root cause (identifikasi sendiri dari membaca kode)

`getSwapPrice` menghitung harga dari saldo pool **saat ini** — dan swap
itu sendiri menggeser saldo, jadi rasio bergerak menguntungkan penyerang
tiap putaran:
```solidity
function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
    return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
}
```
Tidak ada TWAP, tidak ada fee, tidak ada slippage protection. Serangan:
swap bolak-balik dengan seluruh saldo; tiap putaran penyerang mendapat
lebih banyak token daripada yang dimasukkan. Satu jebakan: jumlah swap
harus dibatasi saldo pool token `from` — bila tidak, `swapAmount` bisa
melebihi saldo pool token `to` dan `transferFrom` revert (terjadi di
putaran ke-6 pada simulasi awal saya: 65 TKN2 → 158 TKN1, pool hanya
punya 110). Perbaikan: `amount = min(saldo player, saldo pool from)`.

**Severity (bila nyata): Critical** — pengurasan penuh salah satu sisi
pool (100 token).
**Yang baru vs level 1–10 + DVD:** manipulasi harga AMM tanpa TWAP dari
sisi *trader* (bukan oracle). DVD #11 Puppet / #12 PuppetV2 memakai
oracle spot AMM untuk *pinjaman* — ini varian yang sama tanpa oracle:
rasio pool itu sendiri yang dimanipulasi lewat swap berulang.
**Waktu analisis:** ~4 menit. **Percobaan:** 1/1 (logika), 0 false
positive. (1 perbaikan non-logika: pembatasan jumlah swap, lihat di
atas.)
**Gas `testSolve`:** 898.366.
**PoC:** `benchmarks/ethernaut-dex-solution.t.sol`.

## 3. Level #12 — DexTwo

**Deskripsi:** seperti Dex, tapi `swap` tanpa pemeriksaan token; tujuan:
saldo KEDUA token di pool = 0.

**Kontrak yang dibaca:** `DexTwo.sol` (59 baris), `DexTwoFactory.sol`
(validasi: `balanceOf(token1) == 0 && balanceOf(token2) == 0` — KEDUANYA,
berbeda dengan Dex yang hanya salah satu).

### Root cause (identifikasi sendiri dari membaca kode)

`swap` di DexTwo menghapus `require` validasi token yang ada di Dex:
```solidity
function swap(address from, address to, uint256 amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint256 swapAmount = getSwapAmount(from, to, amount);
    // ...tidak ada cek from/to adalah token1/token2
}
```
`getSwapAmount` membagi dengan saldo pool token `from` — bila token itu
bukan token pool, saldonya 0 → bagi nol. Tapi penyerang bisa **membuat
token sendiri**, mendonasikan 1 unit ke pool (penyebut = 1), lalu menukar
dengan harga yang sepenuhnya ia kendalikan: swap 1 EVL → 100 TKN1
(1×100/1); saldo EVL pool jadi 2 → swap 2 EVL → 100 TKN2 (2×100/2).
Kedua token pool habis.

**Severity (bila nyata): Critical** — pengurasan penuh kedua sisi pool
dengan token buatan sendiri (modal 1 unit token tanpa nilai).
**Yang baru vs level 1–10 + DVD:** validasi input yang hilang (token
arbitrer diterima sebagai `from`) + penyebut harga yang bisa diisi
sendiri. DVD tidak punya varian "bawa token sendiri"; pola ini sejalan
dengan DVD #12 PuppetV2 (harga spot tanpa TWAP) tapi vektornya berbeda:
bukan dump harga, melainkan token palsu.
**Waktu analisis:** ~3 menit. **Percobaan:** 1/1, 0 false positive.
**Gas `testSolve`:** 1.064.104.
**PoC:** `benchmarks/ethernaut-dextwo-solution.t.sol`.

## 4. Level #13 — PuzzleWallet

**Deskripsi:** proxy + wallet; tujuan: `admin` proxy = player (awal: admin
= factory, wallet berisi 0.001 ether, `maxBalance` = 100 ether).

**Kontrak yang dibaca:** `PuzzleWallet.sol` (91 baris: `PuzzleProxy` +
`PuzzleWallet`), `PuzzleWalletFactory.sol` (validasi: `proxy.admin() ==
_player`).

### Root cause (identifikasi sendiri dari membaca kode)

Tiga cacat bergabung — semuanya soal **tabrakan storage proxy vs
implementasi**:

1. `PuzzleProxy` punya `pendingAdmin` (slot 0) dan `admin` (slot 1);
   `PuzzleWallet` punya `owner` (slot 0) dan `maxBalance` (slot 1).
   `proposeNewAdmin(player)` menulis slot 0 proxy → dalam layout wallet
   slot 0 adalah `owner` → penyerang jadi owner.
2. `multicall` memakai `delegatecall` untuk tiap item, dan guard
   "deposit hanya sekali" (`depositCalled`) hanya hidup di **satu frame**
   multicall. Memanggil `multicall` bersarang (multicall di dalam
   multicall) mereset guard — `deposit()` dieksekusi 2× dengan `msg.value`
   yang sama (delegatecall mempertahankan `msg.value`): kirim 0.001 ether
   → `balances[player]` = 0.002 ether.
3. `setMaxBalance` menulis slot 1 — dalam layout proxy slot 1 adalah
   `admin`. Syaratnya saldo wallet = 0 dan pemanggil whitelisted.

Rantai: `proposeNewAdmin(player)` → `addToWhitelist(player)` →
`multicall([deposit, multicall([deposit])])` dengan 0.001 ether →
`execute(player, 0.002 ether)` menguras seluruh saldo wallet (0.002
ether) → `setMaxBalance(uint256(uint160(player)))` → admin = player.

**Severity (bila nyata): Critical** — pengambilalihan admin proxy
(penguasaan penuh kontrak upgradeable) + pengurasan saldo.
**Yang baru vs level 1–10 + DVD:** tabrakan storage proxy/implementasi
(ini yang pertama di seluruh benchmark) + guard reentrancy yang hanya
berlaku per-frame + deposit ganda via `msg.value` yang dipakai ulang.
DVD #7 Climber menyentuh upgradeability (timelock + UUPS) tapi bukan
tabrakan slot; ini melengkapi pola proxy.
**Waktu analisis:** ~5 menit. **Percobaan:** 1/1, 0 false positive.
**Gas `testSolve`:** 259.093.
**PoC:** `benchmarks/ethernaut-puzzlewallet-solution.t.sol`.

## 5. Level #14 — Motorbike

**Deskripsi:** proxy UUPS (EIP-1967); tujuan: Engine (implementation)
tidak lagi berupa kontrak (`extcodesize == 0`).

**Kontrak yang dibaca:** `Motorbike.sol` (99 baris, Solidity <0.7.0:
`Motorbike` proxy + `Engine` UUPS), `MotorbikeFactory.sol` (validasi:
`!Address.isContract(engines[_instance])`).

### Root cause (identifikasi sendiri dari membaca kode)

`Engine.initialize()` hanya pernah dipanggil lewat `delegatecall` di
**konteks proxy** (constructor `Motorbike`) — storage Engine sendiri
tidak pernah terinisialisasi:
```solidity
function initialize() external initializer {
    horsePower = 1000;
    upgrader = msg.sender;   // <- di konteks proxy: upgrader = factory
}
```
Siapa pun bisa memanggil `initialize()` langsung di alamat Engine dan
menjadi `upgrader` dari Engine itu sendiri. Lalu `upgradeToAndCall`
(delegatecall ke implementasi baru + eksekusi data) dipakai untuk
meng-upgrade Engine ke kontrak penyerang yang `selfdestruct` — dalam
konteks Engine, jadi Engine hancur.

**Dua kegagalan non-logika (dicatat jujur — keduanya soal harness,
bukan root cause):**

1. **Percobaan pertama gagal di assert** padahal trace menunjukkan
   `SELFDESTRUCT` sudah dieksekusi. Penyebab: **EIP-6780 (Cancun)** —
   `SELFDESTRUCT` hanya menghapus kode bila kontrak dibuat di transaksi
   yang SAMA. Instance dibuat di `setUp()` (transaksi berbeda dari
   `testSolve()`), jadi kode Engine tetap ada dan `validateInstance`
   tetap false. Perbaikan: buat instance BARU di dalam `testSolve()`
   lalu hancurkan di transaksi yang sama → lolos. Ini temuan nyata
   tentang interaksi level lama dengan EVM modern: di chain post-Cancun,
   serangan ini hanya bekerja bila create + destroy dalam satu transaksi.
2. Motorbike Solidity <0.7.0 → pola interface + `deployCode` (fase G).

**Severity (bila nyata): Critical** — penghancuran implementation
kontrak upgradeable (DoS total + hilangnya logika proxy).
**Yang baru vs level 1–10 + DVD:** (a) implementation yang belum
terinisialisasi (UUPS `initialize` yang bisa dipanggil siapa saja) —
DVD #7 Climber memakai upgrade via timelock, bukan celah init; (b)
**EIP-6780**: pertama kalinya benchmark ini menemukan perilaku EVM
modern yang mengubah hasil exploit — pelajaran yang tidak ada di DVD.
**Waktu analisis:** ~4 menit (logika) + ~10 menit debug EIP-6780.
**Percobaan:** 1 gagal (harness/EIP-6780) lalu 1/1 setelah perbaikan.
0 false positive logika.
**Gas `testSolve`:** 747.723 (termasuk pembuatan instance baru di dalam
test).
**PoC:** `benchmarks/ethernaut-motorbike-solution.t.sol`.

## 6. Level #15 — Elevator

**Deskripsi:** lift yang bertanya ke gedung apakah lantai terakhir;
tujuan: `top == true`.

**Kontrak yang dibaca:** `Elevator.sol` (20 baris), `ElevatorFactory.sol`
(validasi: `elevator.top()`).

### Root cause (identifikasi sendiri dari membaca kode)

`goTo` memanggil `isLastFloor` **dua kali** dan mempercayai kedua
jawaban itu konsisten:
```solidity
function goTo(uint256 _floor) public {
    Building building = Building(msg.sender);
    if (!building.isLastFloor(_floor)) {
        floor = _floor;
        top = building.isLastFloor(floor);   // <-- panggilan kedua
    }
}
```
Kontrak penyerang menjawab berbeda tiap panggilan: pertama `false`
(masuk ke cabang), kedua `true` (menetapkan `top = true`).

**Severity (bila nyata): Medium** — logika state yang bergantung pada
jawaban eksternal yang berubah-ubah; di kontrak nyata, pola ini
(dua kali membaca oracle/state eksternal dan mengasumsikan konsistensi)
adalah sumber bug check-then-use.
**Yang baru vs level 1–10 + DVD:** serangan stateful-view: fungsi
`view` yang seharusnya murni ternyata berubah-ubah. DVD tidak punya
varian ini; ini melengkapi pola oracle (Puppet: harga berubah karena
aksi penyerang; Elevator: jawaban berubah karena state penyerang).
**Waktu analisis:** ~2 menit. **Percobaan:** 1/1, 0 false positive.
**Gas `testSolve`:** 282.666.
**PoC:** `benchmarks/ethernaut-elevator-solution.t.sol`.

## 7. Level #16 — Privacy

**Deskripsi:** brankas dengan password; tujuan: `locked == false`.

**Kontrak yang dibaca:** `Privacy.sol` (30 baris), `PrivacyFactory.sol`
(data = 3 hash dari `tx.origin`; validasi: `!locked`).

### Root cause (identifikasi sendiri dari membaca kode)

Sama seperti Vault (level #8): `private` hanya menyembunyikan dari
compiler. Yang membedakan adalah **layout storage yang harus dihitung
dengan benar** — tiga variabel kecil di-pack dalam satu slot:
```solidity
bool public locked = true;          // slot 0
uint256 public ID = block.timestamp; // slot 1
uint8 private flattening = 10;       // slot 2 (bersama 2 variabel berikut)
uint8 private denomination = 255;
uint16 private awkwardness = uint16(block.timestamp);
bytes32[3] private data;             // slot 3, 4, 5
```
`data[2]` ada di slot 5; kunci = `bytes16(data[2])` (16 byte pertama).
Serangan: `vm.load(instance, 5)` → `unlock(bytes16(data2))`.

**Severity (bila nyata): High** — rahasia on-chain adalah publik;
di kontrak nyata ini berarti kebocoran kredensial/otorisasi.
**Yang baru vs level 1–10 + DVD:** varian Vault dengan packing slot
yang harus dihitung (bukan sekadar slot 1). DVD tidak punya level
storage-layout; ini memperkuat skill membaca storage (dipakai juga di
analisis proxy/EIP-1967 dan Motorbike).
**Waktu analisis:** ~2 menit. **Percobaan:** 1/1, 0 false positive.
**Gas `testSolve`:** 42.702.
**PoC:** `benchmarks/ethernaut-privacy-solution.t.sol`.

## 8. Level #17 — Gatekeeper One

**Deskripsi:** tiga gerbang; tujuan: `entrant == player`.

**Kontrak yang dibaca:** `GatekeeperOne.sol` (28 baris),
`GatekeeperOneFactory.sol` (validasi: `entrant == _player`).

### Root cause (identifikasi sendiri dari membaca kode)

Tiga gerbang, tiga kelemahan:

1. `gateOne`: `msg.sender != tx.origin` — lewati dengan memanggil lewat
   kontrak perantara.
2. `gateTwo`: `gasleft() % 8191 == 0` — gas yang tersisa saat modifier
   dicek harus kelipatan 8191. Brute force: coba 8191 nilai gas
   berurutan lewat low-level `call` — salah satunya pasti mengenai
   residu 0 (biaya: ~5,3 juta gas, hampir seluruhnya dari percobaan
   yang gagal).
3. `gateThree`: `uint32(key64) == uint16(key64) == uint16(tx.origin)`
   dan `uint32(key64) != key64`. Untuk player `0xBEEF`:
   `key64 = 0x000000010000BEEF` (low32 = 0xBEEF, high32 ≠ 0).

**Satu kegagalan non-logika (dicatat jujur):** percobaan pertama gagal
di `validateInstance` padahal `enter()` mengembalikan `true` — trace
menunjukkan `entrant()` = DefaultSender, bukan player. Penyebab:
`vm.startPrank(player)` (1 argumen) **hanya mengubah `msg.sender`,
bukan `tx.origin`** di Foundry. Perbaikan: `vm.startPrank(player,
player)` (2 argumen) — baru `tx.origin` ikut menjadi player. Pelajaran
harness yang sama juga memperbaiki Gatekeeper Two.

**Severity (bila nyata): High** — pengambilalihan gerbang akses;
gateTwo (brute force gas) adalah satu-satunya gerbang yang benar-benar
menahan, dan ia rapuh: gas adalah parameter yang dikendalikan pemanggil.
**Yang baru vs level 1–10 + DVD:** (a) gerbang berbasis gas
(`gasleft() % N`) — belum ada di seluruh benchmark; (b) manipulasi
byte-level pada kunci (masking bit) — varian baru dari autentikasi.
**Waktu analisis:** ~5 menit (logika) + ~8 menit debug prank/tx.origin.
**Percobaan:** 1 gagal (harness) lalu 1/1 setelah perbaikan.
0 false positive logika.
**Gas `testSolve`:** 5.314.837 (didominasi brute force gas).
**PoC:** `benchmarks/ethernaut-gatekeeperone-solution.t.sol`.

## 9. Level #18 — Gatekeeper Two

**Deskripsi:** tiga gerbang; tujuan: `entrant == player`.

**Kontrak yang dibaca:** `GatekeeperTwo.sol` (30 baris),
`GatekeeperTwoFactory.sol` (validasi: `entrant == _player`).

### Root cause (identifikasi sendiri dari membaca kode)

1. `gateOne`: `msg.sender != tx.origin` — lewat kontrak perantara.
2. `gateTwo`: `extcodesize(caller()) == 0` — `extcodesize` sebuah
   kontrak adalah 0 **hanya selama konstruksinya**. Jadi serangan harus
   dieksekusi dari constructor kontrak penyerang.
3. `gateThree`: `uint64(keccak256(msg.sender)) ^ uint64(key) ==
   type(uint64).max` → `key = keccak256(attacker) ^ 0xFFFF...FFFF`
   (dihitung di constructor, `msg.sender` = alamat kontrak penyerang).

Kegagalan yang sama dengan Gatekeeper One (prank 1 argumen tidak
mengubah `tx.origin`) diperbaiki dengan cara yang sama:
`vm.startPrank(player, player)`.

**Severity (bila nyata): High** — pengambilalihan gerbang akses;
`extcodesize == 0` sebagai bukti "bukan kontrak" adalah asumsi yang
salah (konstruktor adalah jendela di mana kontrak belum punya kode).
**Yang baru vs level 1–10 + DVD:** (a) pemeriksaan `extcodesize`
sebagai gate — belum ada di seluruh benchmark; (b) serangan dari
constructor — pola baru (DVD tidak punya satu pun exploit yang
dieksekusi dari constructor).
**Waktu analisis:** ~3 menit (logika) + debug bersama Gatekeeper One.
**Percobaan:** 1 gagal (harness) lalu 1/1 setelah perbaikan.
0 false positive logika.
**Gas `testSolve`:** 148.939.
**PoC:** `benchmarks/ethernaut-gatekeepertwo-solution.t.sol`.

## 10. Level #19 — Preservation

**Deskripsi:** kontrak dengan dua library; tujuan: `owner == player`.

**Kontrak yang dibaca:** `Preservation.sol` (38 baris),
`PreservationFactory.sol` (validasi: `owner == _player`).

### Root cause (identifikasi sendiri dari membaca kode)

`setFirstTime` melakukan `delegatecall` ke library — dan fungsi library
`setTime` menulis ke **slot 0**:
```solidity
// LibraryContract (layout sendiri): uint256 storedTime; // slot 0
function setTime(uint256 _time) public {
    storedTime = _time;
}
```
Dalam konteks Preservation, slot 0 adalah `timeZone1Library`. Jadi
`setFirstTime(uint256(uint160(attacker)))` **menimpa alamat library**
dengan alamat kontrak penyerang. Panggilan `setFirstTime` berikutnya
mendelegatecall kontrak penyerang — yang `setTime`-nya (dengan layout
storage yang sama: slot 0, 1, 2 = timeZone1Library, timeZone2Library,
owner) menetapkan `owner = msg.sender`.

**Severity (bila nyata): Critical** — pengambilalihan owner kontrak
yang memakai library via delegatecall; kelas yang sama dengan Parity
wallet ($150 jt+): alamat library adalah state yang bisa ditulis lewat
fungsi library itu sendiri.
**Yang baru vs level 1–10 + DVD:** (a) delegatecall ke library yang
menulis slot 0 = alamat library itu sendiri — ini adalah varian
delegatecall yang belum ada: DVD #8 Backdoor memakai delegatecall di
`setup()`, level #6 Delegation memakai delegatecall ke selector
arbitrer, tapi ini memakai fungsi library yang *sah* untuk menimpa
pointer library; (b) dua langkah: timpa pointer dulu, baru eksekusi
kode penyerang.
**Waktu analisis:** ~4 menit. **Percobaan:** 1/1, 0 false positive.
**Gas `testSolve`:** 245.105.
**PoC:** `benchmarks/ethernaut-preservation-solution.t.sol`.

## 11. Level #20 — Recovery

**Deskripsi:** kontrak yang membuat token lalu "kehilangan" alamatnya;
tujuan: saldo alamat yang hilang = 0 (awal: 0.001 ether dikirim ke sana).

**Kontrak yang dibaca:** `Recovery.sol` (37 baris), `RecoveryFactory.sol`
(validasi: `lostAddress.balance == 0`).

### Root cause (identifikasi sendiri dari membaca kode)

Alamat kontrak yang dibuat dengan `CREATE` adalah deterministik:
`keccak256(RLP([creator, nonce]))[12:]`. Token dibuat oleh Recovery
sebagai kontrak pertamanya (nonce 1), jadi alamatnya dapat dihitung
tanpa pernah melihat factory:
```solidity
address lost = address(uint160(uint256(keccak256(
    abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(instance), bytes1(0x01))
))));
```
`SimpleToken.destroy()` bersifat publik dan `selfdestruct` ke alamat
yang diberikan — panggil dengan `player` sebagai penerima, saldo 0.001
ether pindah, saldo alamat hilang = 0.

**Satu kegagalan non-logika:** compile gagal — `SimpleToken` punya
`receive()` payable sehingga tipenya payable; cast dari `address`
biasa tidak diizinkan. Perbaikan: `address payable lost = payable(...)`.

**Severity (bila nyata): High** — dana yang "hilang" di alamat yang
dapat diprediksi sebenarnya dapat diambil siapa saja yang menghitung
alamatnya; di kontrak nyata ini adalah kelas "dana terkunci yang
ternyata bisa diambil".
**Yang baru vs level 1–10 + DVD:** prediksi alamat CREATE dari nonce —
DVD #13 SafeMiners memakai pola yang sama (CREATE yang dapat
diprediksi), tapi di sana rantai prediksinya lebih panjang (Hardhat #1
→ attack contract → sweeper nonce 66); di sini satu langkah dan
langsung dari factory. Konfirmasi bahwa pola ini general.
**Waktu analisis:** ~3 menit. **Percobaan:** 1/1 (logika), 0 false
positive. (1 kegagalan compile harness: cast `address` → payable.)
**Gas `testSolve`:** 47.296.
**PoC:** `benchmarks/ethernaut-recovery-solution.t.sol`.

## 12. Ringkasan akhir — Ethernaut 10/10 (level 11–20) SELESAI

| # | Level | Gas testSolve | Severity | Percobaan | Pola |
|---|---|---|---|---|---|
| 11 | Dex | 898.366 | Critical | 1/1 | harga AMM dari saldo pool, swap bolak-balik |
| 12 | DexTwo | 1.064.104 | Critical | 1/1 | token arbitrer + penyebut harga diisi sendiri |
| 13 | PuzzleWallet | 259.093 | Critical | 1/1 | tabrakan storage proxy + multicall bersarang |
| 14 | Motorbike | 747.723 | Critical | 1 gagal (EIP-6780) | init UUPS tak terlindungi + selfdestruct |
| 15 | Elevator | 282.666 | Medium | 1/1 | jawaban stateful dari panggilan eksternal |
| 16 | Privacy | 42.702 | High | 1/1 | storage layout + packing slot |
| 17 | GatekeeperOne | 5.314.837 | High | 1 gagal (prank) | gerbang gas + masking kunci |
| 18 | GatekeeperTwo | 148.939 | High | 1 gagal (prank) | extcodesize 0 di constructor + XOR kunci |
| 19 | Preservation | 245.105 | Critical | 1/1 | delegatecall library menimpa pointer library |
| 20 | Recovery | 47.296 | High | 1/1 | prediksi alamat CREATE (nonce 1) |

**SKOR AKHIR: 10/10.** Akurasi identifikasi 10/10 (semua root cause
benar pada percobaan pertama), 0 false positive logika, waktu analisis
~2–5 menit per level (identifikasi dari membaca kontrak + tulis test).
Total waktu sesi didominasi debug harness (±20 menit: EIP-6780 di
Motorbike, prank 1 vs 2 argumen di Gatekeeper One/Two, cast payable di
Recovery) — bukan analisis logikanya.

### Catatan kejujuran (wajib dibaca)

1. **Level 11–20 murni.** Semua root cause diidentifikasi dari membaca
   kontrak level + factory saja. Tidak ada file test repo yang dibaca
   (pelajaran dari kontaminasi Fallback di fase G — kali ini file
   `test/levels/` repo tidak dibuka sama sekali), tidak ada writeup/blog
   yang dibaca.
2. **Tiga kegagalan yang terjadi adalah kegagalan harness, bukan
   logika:** (a) Motorbike: EIP-6780 — selfdestruct tidak menghapus kode
   bila kontrak dibuat di transaksi berbeda (diperbaiki: create + destroy
   dalam satu transaksi); (b) Gatekeeper One/Two: `vm.startPrank`
   1 argumen tidak mengubah `tx.origin` (diperbaiki: prank 2 argumen);
   (c) Recovery: cast `address` → kontrak payable (diperbaiki:
   `address payable`). Tidak ada satu pun hipotesis root cause yang
   salah.
3. **Level 11–20 memang lebih sulit dari 1–10** — bukan karena
   polanya lebih kabur, melainkan karena exploit-nya berantai:
   PuzzleWallet (3 langkah), Preservation (2 langkah), Motorbike
   (init → upgrade → selfdestruct), Dex (loop adaptif). Tapi
   pola dasarnya masih dikenal dari literatur (AMM tanpa TWAP,
   tabrakan proxy, UUPS, CREATE deterministik). Pengukur sesungguhnya
   adalah level 21+ (NaughtCoin, DoubleEntryPoint, GoodSamaritan,
   GatekeeperThree, AlienCodex, Denial, Shop, dll.) — di situlah pola
   yang belum dikenal muncul.

### Pola baru vs level 1–10 + DVD (yang belum dimiliki benchmark sebelumnya)

- Harga AMM dari saldo pool yang dimanipulasi lewat swap (Dex) dan
  token arbitrer sebagai `from` (DexTwo).
- Tabrakan storage proxy/implementasi (PuzzleWallet) — pertama kalinya.
- Implementation UUPS yang belum terinisialisasi (Motorbike).
- **EIP-6780**: perilaku `SELFDESTRUCT` pasca-Cancun yang mengubah hasil
  exploit — pertama kalinya benchmark ini menemukan interaksi dengan
  perilaku EVM modern.
- Gerbang berbasis gas (`gasleft() % N`) dan `extcodesize == 0`
  (Gatekeeper One/Two) — belum ada di seluruh benchmark.
- Serangan dari constructor (Gatekeeper Two).
- Fungsi eksternal yang menjawab berbeda tiap panggilan / stateful-view
  (Elevator).
- Delegatecall library yang menimpa pointer library-nya sendiri
  (Preservation).
- Prediksi alamat CREATE (Recovery) — konfirmasi pola DVD #13 SafeMiners.

### Pola yang sudah dikenal (konfirmasi, bukan penemuan)

- `private` storage dapat dibaca (Privacy) — sejalan dengan Vault (#8).
- Harga spot AMM tanpa TWAP (Dex/DexTwo) — sejalan dengan DVD #11/#12
  Puppet/PuppetV2 (di sana untuk pinjaman, di sini untuk pengurasan
  pool).
- Prediksi alamat CREATE (Recovery) — sejalan dengan DVD #13 SafeMiners.

### Pelajaran untuk perburuan bounty nyata

1. **EIP-6780 mengubah kalkulus selfdestruct.** Sejak Cancun,
   `SELFDESTRUCT` hanya menghapus kode bila kontrak dibuat di transaksi
   yang sama. Exploit yang mengandalkan penghancuran kontrak harus
   dirancang satu transaksi — atau tidak bekerja sama sekali di chain
   modern. Selalu periksa `evm_version` target saat menulis PoC.
2. **`vm.prank` 1 argumen ≠ `tx.origin`.** Di Foundry, prank 1 argumen
   hanya mengubah `msg.sender`; untuk mengubah `tx.origin` pakai
   `startPrank(addr, addr)` / `prank(addr, addr)`. Ini menjebak dua
   level sekaligus.
3. **Baca `validateInstance` dulu** — kondisi sukses resmi tiap level ada
   di factory (mis. DexTwo menuntut KEDUA token habis, Dex hanya salah
   satu; Recovery menuntut saldo alamat hilang = 0). Membacanya mencegah
   salah tafsir tujuan.
4. **Batasi jumlah swap dengan saldo pool** — di AMM tanpa TWAP,
   `swapAmount` bisa melebihi saldo pool dan revert; `amount =
   min(saldo, saldo pool from)` adalah batas aman.
5. **Severity jujur:** 5 Critical (Dex, DexTwo, PuzzleWallet,
   Motorbike, Preservation), 4 High (Privacy, Gatekeeper One,
   Gatekeeper Two, Recovery), 1 Medium (Elevator) — tidak ada yang
   dibesar-besarkan (Elevator tetap Medium: tidak ada dana yang
   langsung dicuri).

### Langkah berikut

- Level 21–30 Ethernaut (NaughtCoin, DoubleEntryPoint, GoodSamaritan,
  GatekeeperThree, AlienCodex, Denial, Shop, Stake, MagicNumber,
  etc.) — pengukur yang sesungguhnya.
- Integrasikan pola baru (AMM tanpa TWAP, tabrakan storage proxy,
  init UUPS, gerbang gas/extcodesize, EIP-6780, prediksi CREATE) ke
  skill `bounty-hunter` / `sc-audit` pada revisi berikut.

**Baseline Ethernaut 11–20 SELESAI — 10/10, terverifikasi segar.**
Seluruh file solusi ada di `benchmarks/ethernaut-*-solution.t.sol`
(20 file total untuk level 1–20).
