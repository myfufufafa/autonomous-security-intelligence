# Ethernaut — Baseline (Level 21–30)

**Misi:** Autonomous Bounty Intelligence & Skill Evolution — Pass 2 fase I
(PENUTUP benchmark Ethernaut)
**Tanggal:** 16 November 2026
**Sumber:** https://github.com/OpenZeppelin/ethernaut (MIT, clone `--depth 1`
ke `/tmp/ethernaut-baseline`, HEAD `d05643a`, 19 Nov 2025)
**Status:** Level 21–30 SELESAI — skor 10/10. Verifikasi segar: `forge test`
di proyek minimal `/tmp/ethernaut-work`: **60 tests passed, 0 failed**
(30× `testInit` + 30× `testSolve`, level 1–30; semua `testSolve`
menegaskan `factory.validateInstance(...) == true`).
**Lokasi kerja:** proyek minimal `/tmp/ethernaut-work` (sama dengan fase G/H,
ditambah 20 file level 21–30 + `src/base/Level-05.sol` +
`src/helpers/Ownable-05.sol`). Semua solusi yang lolos disalin SEGERA ke
repo ini: `benchmarks/ethernaut-<nama>-solution.t.sol` (10 file baru;
total 30 untuk level 1–30).

## 1. Setup proyek — hasil uji

| Aspek | Hasil |
|---|---|
| Proyek fase G/H dipakai ulang | `/tmp/ethernaut-work` sudah berisi 40 file level 1–20 + lib vendored (forge-std, OZ-06, OZ-08). Tambah 20 file level 21–30 (10 kontrak + 10 factory) + `base/Level-08.sol`, `base/Level-05.sol` + `helpers/Ownable-05.sol`. Build: **OK** (solc 0.5.17 + 0.6.12 + 0.8.30). |
| AlienCodex (<0.7.0) | Satu-satunya level 0.5 di batch ini (pragma `^0.5.0`). Pola fase G dipakai lagi: interface + `deployCode("AlienCodexFactory.sol:AlienCodexFactory")` dari test 0.8. solc 0.5.x berhasil diunduh otomatis oleh Foundry. |
| MagicNum | Di repo ini bernama `MagicNum.sol` / `MagicNumFactory.sol` (bukan `MagicNumber`). |
| 8 level lain | Semua `^0.8.0` — import langsung ke test 0.8 seperti biasa. |
| RPC / fork | Tidak dibutuhkan — semua level berjalan lokal (tanpa fork). |
| Foundry | 1.9.0 — kompatibel. Seluruh suite 60 test berjalan ~39 ms (plus ~2 detik compile). |

**Pola harness (sama dengan fase G/H):** tiap file test men-deploy factory
langsung, memanggil `factory.createInstance(player)`, menjalankan exploit,
lalu menegaskan `factory.validateInstance(...) == true`. Tidak memakai
kontrak `Ethernaut.sol` / `Utils` repo.

## 2. Level #21 — NaughtCoin

**Deskripsi:** ERC20 dengan timelock 10 tahun: `transfer()` player
terkunci sampai timelock berakhir. Tujuan: saldo player = 0.

**Kontrak yang dibaca:** `NaughtCoin.sol`, `NaughtCoinFactory.sol`
(validasi: `balanceOf(player) == 0`).

### Root cause (identifikasi sendiri dari membaca kode)

`transfer()` di-override dengan cek timelock — tapi `transferFrom()`
**tidak di-override**, jadi jalur itu memakai implementasi ERC20 standar
tanpa cek timelock:

```solidity
function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
    return super.transfer(_to, _value);
}
// transferFrom() tidak ada — approve + transferFrom menguras saldo.
```

Serangan: `approve(penyerang, saldo)` lalu `transferFrom(player, penyerang, saldo)`.

**Severity (bila nyata): High** — pengurasan penuh saldo token yang
seharusnya terkunci 10 tahun.
**Yang baru vs level 1–20 + DVD:** override selektif yang tidak lengkap —
penguncian diterapkan di satu fungsi tapi jalur setara dibiarkan terbuka.
(Pola sepupu: Token #6 underflow, tapi mekanismenya berbeda — di sini
bukan aritmetika, melainkan kelalaian override.)

## 3. Level #22 — DoubleEntryPoint

**Deskripsi:** Vault berisi token `DET` (DelegateERC20) + `LGT`
(LegacyToken). `sweepToken()` menguras `LGT` dari vault — tapi
`DET.delegateTransfer()` di dalamnya mentransfer `DET` vault juga.
Tujuan: sweep harus GAGAL dan vault tetap memegang `DET`.

**Kontrak yang dibaca:** `DoubleEntryPoint.sol` (DET, LGT, Forta,
CryptoVault), `DoubleEntryPointFactory.sol` (validasi: sweep revert +
`DET.balanceOf(vault) == 100`).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function sweepToken(IERC20 token) public {
    require(token != cryptoVault.underlying(), "Can't transfer underlying token");
    token.transfer(sweeper, token.balanceOf(address(cryptoVault)));
}
```

`sweepToken(LGT)` memanggil `LGT.transfer(...)` → `LGT` mendelegasikan ke
`DET.delegateTransfer(to, value, origSender=vault)` → `DET` vault ikut
terkirim. Satu-satunya pertahanan: **detection bot Forta**. `fortaNotify`
memanggil `bot.handleTransaction(user, msgData)`; bila bot memanggil
`forta.raiseAlert(user)`, `delegateTransfer` revert dan sweep gagal.
Bot harus raise alert bila `origSender == vault` (decode dari `msgData`
`delegateTransfer(to, value, origSender)`).

**Severity (bila nyata): Critical** — pengurasan penuh vault lewat
jalur delegasi tersembunyi.
**Yang baru vs level 1–20 + DVD:** sistem monitoring (Forta detection
bot) sebagai permukaan exploit/pertahanan — pertama kalinya benchmark
ini memakai deteksi on-chain sebagai mekanisme keamanan, bukan sekadar
logika kontrak.

**Kegagalan harness (bukan logika):** `vm.prank(player)` habis dimakan
panggilan view `instance.forta()` sebelum `setDetectionBot` — prank
hanya berlaku satu panggilan. Perbaikan: baca alamat Forta dulu, baru
prank, lalu `setDetectionBot`. (Pelajaran yang sama dengan fase H, tapi
di sini yang memakan prank adalah panggilan view, bukan transaksi.)

## 4. Level #23 — GoodSamaritan

**Deskripsi:** Wallet berisi 10^4 koin; `requestDonation()` memberi 10
koin per panggilan bila saldo cukup. Tujuan: seluruh saldo wallet = 0.

**Kontrak yang dibaca:** `GoodSamaritan.sol`, `GoodSamaritanFactory.sol`
(validasi: `coin.balanceOf(wallet) == 0`).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function requestDonation() external returns (bool enoughBalance) {
    if (wallet.balance() >= 10) {
        bool success = false;
        try wallet.donate10(msg.sender) returns (bool b) {
            success = b;
        } catch (bytes memory err) {
            if (keccak256(abi.encodeWithSignature("NotEnoughBalance()")) == keccak256(err)) {
                wallet.transferRemainder(msg.sender);
            }
        }
        ...
```

`donate10` memanggil `notify(amount)` pada penerima. Bila `notify`
revert dengan custom error **persis** `NotEnoughBalance()`, catch
mengira wallet kehabisan saldo dan memanggil `transferRemainder` —
seluruh saldo mengalir ke penyerang. Serangan: kontrak penyerang yang
`notify(10)`-nya revert `NotEnoughBalance()` hanya pada panggilan
pertama (amount == 10); panggilan kedua (transferRemainder) tidak
revert.

**Severity (bila nyata): High** — pengurasan penuh wallet lewat
penyalahgunaan error handling.
**Yang baru vs level 1–20 + DVD:** control flow berbasis tipe error /
try-catch — revert yang seharusnya sinyal kegagalan dipakai sebagai
pemicu jalur darurat. Pertama kalinya custom error menjadi vektor
serangan.

## 5. Level #24 — GatekeeperThree

**Deskripsi:** Tiga gerbang: (1) `msg.sender == owner` dan
`tx.origin != owner`; (2) `allowEntrance` — password dari SimpleTrick;
(3) saldo kontrak > 0,001 ether DAN `send(0,001 ether)` ke owner GAGAL.
Tujuan: `entrant == player`.

**Kontrak yang dibaca:** `GatekeeperThree.sol` (SimpleTrick),
`GatekeeperThreeFactory.sol` (validasi: `entrant == player`).

### Root cause (identifikasi sendiri dari membaca kode)

- **gateOne:** `construct0r()` — constructor yang salah eja — bisa
  dipanggil siapa pun dan menjadikan pemanggil `owner`. Pemilik harus
  kontrak (bukan EOA) karena `tx.origin != owner`.
- **gateTwo:** password = `block.timestamp` saat `createTrick()`,
  tersimpan di slot 2 SimpleTrick (target slot 0, trick slot 1) — dibaca
  via `vm.load`, lalu `getAllowance(password)`.
- **gateThree:** kirim 0,002 ether ke kontrak, lalu `enter()` — `send`
  ke owner gagal karena owner adalah kontrak penyerang yang SENGAJA
  tanpa `receive()`/`fallback()`.
- `enter()` dipanggil dengan `tx.origin = player` (`startPrank` 2
  argumen — pelajaran fase H).

**Severity (bila nyata): High** — bypass tiga lapis otorisasi sekaligus
(masing-masing lapis lemah, kombinasinya tetap lolos).
**Yang baru vs level 1–20 + DVD:** tidak ada pola yang benar-benar baru
— kombinasi tiga pola yang sudah dikenal (constructor typo seperti
Fallout #2; password di storage slot seperti Vault #8; gerbang
berbasis `send` yang gagal seperti King #9; `tx.origin` seperti
Telephone #4). Nilai level ini adalah rantai: ketiga gerbang harus
dipecahkan sekaligus dalam satu rencana.

## 6. Level #25 — AlienCodex

**Deskripsi:** Kontrak Solidity 0.5 dengan array `bytes32[] codex`;
`revise(i, content)` menimpa elemen array. Tujuan: `owner() == player`.

**Kontrak yang dibaca:** `AlienCodex.sol` (+ `Ownable-05.sol`),
`AlienCodexFactory.sol` (validasi: `owner() == player`).

### Root cause (identifikasi sendiri dari membaca kode)

`retract()` mengurangi panjang array tanpa checked arithmetic (Solidity
0.5):

```solidity
function retract() public contacted {
    codex.length--;
}
```

Pada array kosong, `length--` UNDERFLOW → length = 2^256 − 1. Setelah
itu `revise(i, ...)` bisa menulis ke slot array mana pun:
slot data = `keccak256(slotLength) + i`. Untuk menimpa slot 0 (`_owner`),
pakai `i = 2^256 − keccak256(slotLength)`.

**Jebakan yang memakan waktu debug paling lama di batch ini — storage
packing lintas inheritance.** Tebakan awal (slot 0 = `_owner`, slot 1 =
`contact`, slot 2 = `codex.length`) SALAH. Fakta yang dibuktikan via
`vm.load` per slot:

- Slot 0 = `_owner` (20 byte, Ownable-05) **+ `contact` (bool, 1 byte,
  TERPACKING di byte ke-20 slot 0)** — compiler Solidity mem-packing
  variabel `bool` dari kontrak turunan ke sisa slot 0 milik base
  contract.
- Slot 1 = `codex.length` (bukan slot 2).
- Data array di `keccak256(1) + i` (bukan `keccak256(2)`).

Bukti: setelah `makeContact()`, slot 0 berubah menjadi
`factory | (1 << 160)` — bit `contact=true` tepat di atas alamat owner;
setelah `retract()`, slot 1 terbaca `0xFFFF...FFFF` (2^256−1), bukan
slot 2. Indeks yang benar: `i = 2^256 − keccak256(abi.encode(1))`.

**Dua jebakan alat selama debug:**
1. `python3 hashlib.sha3_256` adalah **NIST SHA3, bukan Keccak-256**
   (parameter padding berbeda) — hasilnya salah. Keccak yang benar
   dihitung via `pycryptodome` (`Crypto.Hash.keccak`) dan dikonfirmasi
   cocok dengan indeks di trace.
2. Binary `cast` tidak ada di PATH — verifikasi dilakukan via
   `vm.load` di test probe Foundry, bukan via CLI.

**Severity (bila nyata): Critical** — pengambilalihan ownership penuh
lewat underflow panjang array.
**Yang baru vs level 1–20 + DVD:** (a) underflow panjang array dinamis
di Solidity 0.5 — pertama kalinya; (b) storage packing lintas
inheritance sebagai sumber kesalahan analisis — pertama kalinya, dan
inilah debug tersulit di seluruh benchmark Ethernaut 30 level.

## 7. Level #26 — Denial

**Deskripsi:** Kontrak membagi 1% saldo ke partner (low-level call tanpa
cek return) lalu 1% ke owner. Tujuan: `withdraw()` harus revert.

**Kontrak yang dibaca:** `Denial.sol`, `DenialFactory.sol` (validasi:
`withdraw()` dipanggil dengan gas 1.000.000 harus revert).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function withdraw() public {
    uint256 amountToSend = address(this).balance / 100;
    partner.call{value: amountToSend}("");
    payable(owner).transfer(amountToSend);
    ...
}
```

Bila fallback partner menghabiskan seluruh gas yang diteruskan,
`withdraw()` kehabisan gas dan revert. Kuncinya ada dua:

1. **Aturan EIP-150 (63/64):** `partner.call` hanya meneruskan 63/64
   gas (~984k dari 1M); pemanggil menyimpan ~15,6k. Sisa itu TIDAK
   cukup untuk `transfer` (11.600 gas) + 2× SSTORE
   (`timeLastWithdrawn` + `withdrawPartnerBalances`, ~20k masing-masing)
   → pemanggil OOG di tengah jalan → revert.
2. **`assert(false)` di Solidity 0.8 TIDAK cukup.** Di Solidity <0.8,
   `assert` memakai opcode INVALID (0xfe) yang menghabiskan semua gas.
   Di 0.8+, `assert` adalah REVERT dengan Panic(0x01) yang
   **mengembalikan gas tak terpakai** — low-level call mengembalikan
   `false` (diabaikan), `withdraw()` selesai normal. Percobaan pertama
   dengan `assert(false)` gagal tepat karena ini (trace: Panic revert,
   lalu `validateInstance` mengembalikan `false`).
   Perbaikan: loop tak berujung yang benar-benar membakar gas
   (`while (true) { counter++; }` dengan SSTORE per iterasi).

**Severity (bila nyata): Medium (jujur)** — DoS pada penarikan: dana
terkunci, bukan dicuri. Sama seperti Unstoppable (DVD #1): tidak ada
dana yang langsung hilang, tapi fungsi inti mati selamanya.
**Yang baru vs level 1–20 + DVD:** gas griefing / push-payment DoS +
aturan 63/64 EIP-150 + perubahan semantik `assert` di Solidity 0.8.
Pertama kalinya benchmark ini menuntut perhitungan gas sebagai bagian
dari exploit.

## 8. Level #27 — Shop

**Deskripsi:** Toko menjual item seharga 100; `buy()` memanggil
`_buyer.price()` lalu memeriksa `price >= 100`. Tujuan: harga yang
dibayar < 100.

**Kontrak yang dibaca:** `Shop.sol`, `ShopFactory.sol` (validasi:
`price == 0` setelah pembelian).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function buy() public {
    if (_buyer.price() >= 100) {
        ...
        price = _buyer.price();
        ...
    }
}
```

`buy()` memanggil `_buyer.price()` **DUA kali**: sekali di kondisi `if`,
sekali untuk menetapkan harga. `price()` dideklarasikan `view` — tidak
bisa mengubah state — tapi **bisa MEMBACA state Shop**: panggilan
pertama `isSold == false` → 100; di antaranya `isSold` berubah menjadi
`true`; panggilan kedua → 0. Item dibeli seharga 0.

**Severity (bila nyata): High** — membeli barang seharga 0 (diskon 100%).
**Yang baru vs level 1–20 + DVD:** fungsi `view` yang stateful antar
panggilan dalam satu transaksi — sepupu Elevator (#15, fungsi eksternal
yang menjawab berbeda tiap panggilan), tapi di sini vektornya adalah
`view` yang membaca state pemanggil di tengah eksekusi. "View" ≠
"konstan".

## 9. Level #28 — MagicNum

**Deskripsi:** Sediakan kontrak solver ≤10 byte yang mengembalikan 42
(`0x2a`) saat `whatIsTheMeaningOfLife()` dipanggil. Tujuan:
`solver() != address(0)` dan mengembalikan 42.

**Kontrak yang dibaca:** `MagicNum.sol`, `MagicNumFactory.sol`
(validasi: `solver.whatIsTheMeaningOfLife() == 42`).

### Root cause (identifikasi sendiri dari membaca kode)

Tidak ada kerentanan logika — ini teka-teki bytecode EVM. Solver 10
byte (runtime) + 12 byte (creation):

```
creation: 600a600c600039600a6000f3  (12 byte)
runtime:  602a60005260206000f3      (10 byte)
```

Runtime: `PUSH1 0x2a, PUSH1 0x00, MSTORE, PUSH1 0x20, PUSH1 0x00,
RETURN` — mengembalikan 32 byte = 0x2a (42). Selector calldata
diabaikan — kontrak hanya punya satu fungsi. Creation code menyalin
runtime dari code ke memory lalu mengembalikannya.

**Severity (bila nyata): Medium (jujur)** — ini bukan kerentanan dana;
ini soal ukuran kode dan pemahaman EVM. Dinilai Medium karena pola yang
sama (kontrak minimal hasil rakitan tangan) relevan untuk audit
bytecode, bukan karena ada dana yang dicuri.
**Yang baru vs level 1–20 + DVD:** bytecode EVM rakitan tangan /
kontrak minimal — tidak ada satu pun level sebelumnya yang menuntut
menulis opcode mentah.

**Kegagalan harness (bukan logika):** `testInit` memanggil
`validateInstance` padahal solver masih `address(0)` — pemanggilan
fungsi ke alamat kosong mengembalikan data kosong dan decode revert.
Perbaikan: `testInit` hanya menegaskan `instance.solver() ==
address(0)` (quirk level ini, dicatat di komentar test).

## 10. Level #29 — Switch

**Deskripsi:** Kontrak dengan `flipSwitch(bytes _data)` yang hanya bisa
memanggil `turnSwitchOn()` bila modifier `onlyOff` lolos. Tujuan:
`switchOn == true`.

**Kontrak yang dibaca:** `Switch.sol`, `SwitchFactory.sol` (validasi:
`switchOn == true`).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
modifier onlyOff() {
    bytes32[1] memory selector;
    assembly {
        calldatacopy(selector, 68, 4)
    }
    require(selector[0] == offSelector, "Can only call the off function");
    _;
}
```

Modifier membaca selector dari posisi calldata 68 **secara hardcode**,
dengan asumsi offset `_data` = 0x20 (data mulai di byte 68). Dengan
offset `_data` = 0x60, decoder ABI membaca length di byte 100 dan
`_data` di byte 132 — sementara modifier tetap membaca byte 68.
Payload 136 byte: selector `flipSwitch` [0:4], offset 0x60 [4:36],
filler [36:68], `offSelector` [68:72], filler [72:100], length 4
[100:132], `onSelector` (`turnSwitchOn()`) [132:136].

**Severity (bila nyata): High** — bypass modifier otorisasi lewat
kebingungan layout calldata.
**Yang baru vs level 1–20 + DVD:** hardcoded offset calldata / asumsi
layout ABI yang bisa digeser — pertama kalinya. Peringatan nyata untuk
audit: parsing calldata manual yang mengasumsikan offset tetap adalah
bug.

## 11. Level #30 — Stake

**Deskripsi:** Kontrak staking WETH: `StakeETH` (ETH nyata),
`StakeWETH` (transfer WETH), `Unstake`. Tujuan: `totalStaked >
address(this).balance` DAN `UserStake[player] == 0` DAN
`Stakers[player] == true`.

**Kontrak yang dibaca:** `Stake.sol`, `StakeFactory.sol` (validasi:
`T > B && U == 0 && Stakers[player]`).

### Root cause (identifikasi sendiri dari membaca kode)

```solidity
function StakeWETH(uint256 _amount) public returns (bool) {
    uint256 amount = _amount;
    if (totalStaked == 0) {
        if (WETH.transferFrom(msg.sender, address(this), _amount)) {
            totalStaked += _amount;
            UserStake[msg.sender] += _amount;
        }
    } else {
        WETH.transferFrom(msg.sender, address(this), _amount);
        totalStaked += _amount;
        UserStake[msg.sender] += _amount;
    }
    ...
}
```

Dua cacat berlapis:

1. **Return value `transferFrom` tidak dicek (cabang `else`).**
   `DWETH` di level ini saldonya 0 → `transferFrom` revert diam-diam
   (return `false`), tapi `totalStaked`/`UserStake` tetap naik —
   stake hantu tanpa dana.
2. **State berubah sebelum `send` yang gagal.** `Unstake` memanggil
   `payable(msg.sender).send(amount)` tanpa cek return, lalu tetap
   meng nolkan `UserStake` dan mengurangi `totalStaked`.

Serangan (butuh staker kedua, karena satu pemain saja selalu T == U):
player `StakeETH` 0,002 ether (dana nyata, satu-satunya ETH di kontrak);
kontrak test `StakeWETH` palsu 1 ether (T = 1,002); player `StakeWETH`
palsu 0,002 (U_player = 0,004); player `Unstake(0,004)` — `send` gagal
karena saldo kontrak hanya 0,002, tapi state tetap berubah
(U_player → 0, T tinggal 1,0 dari staker lain). Akhir: T = 1,0 >
B = 0,002, U_player = 0, Stakers[player] = true.

**Severity (bila nyata): Critical** — insolvensi akuntansi: total
stake tercatat melebihi dana yang benar-benar ada (stake hantu).
**Yang baru vs level 1–20 + DVD:** unchecked ERC20 return value —
pola klasik dari literatur audit yang BARU pertama kali muncul di
benchmark ini — plus ordering state-sebelum-send-gagal. Kombinasi
keduanya membuat kondisi validasi yang tampaknya mustahil (T > B
sambil U == 0) menjadi tercapai.

## 12. Ringkasan akhir — Ethernaut 10/10 (level 21–30) SELESAI

| # | Level | Root cause (1 baris) | Severity | Gas testSolve | Status |
|---|---|---|---|---|---|
| 21 | NaughtCoin | `transferFrom` tidak di-override — timelock bisa dilewati | High | 127.615 | ✅ lolos |
| 22 | DoubleEntryPoint | Sweep LGT mendelegasikan transfer DET vault; bot Forta harus raise alert | Critical | 473.775 | ✅ lolos |
| 23 | GoodSamaritan | `notify` revert `NotEnoughBalance()` memicu `transferRemainder` | High | 340.070 | ✅ lolos |
| 24 | GatekeeperThree | `construct0r` typo + password di slot + owner kontrak tanpa receive | High | 631.796 | ✅ lolos |
| 25 | AlienCodex | `retract()` underflow length (0.5) + packing storage lintas inheritance | Critical | 142.228 | ✅ lolos |
| 26 | Denial | Fallback partner bakar gas; `assert` 0.8 tidak cukup (revert, bukan INVALID) | Medium | 1.212.116 | ✅ lolos |
| 27 | Shop | `price()` view dipanggil 2×, membaca `isSold` yang berubah di antaranya | High | 282.341 | ✅ lolos |
| 28 | MagicNum | Solver bytecode 10 byte rakitan tangan, kembalikan 42 | Medium | 152.500 | ✅ lolos |
| 29 | Switch | Modifier baca selector dari offset calldata hardcode 68 | High | 53.799 | ✅ lolos |
| 30 | Stake | `transferFrom` tak dicek + state berubah sebelum `send` gagal | Critical | 400.881 | ✅ lolos |

**Skor: 10/10. Total gas testSolve level 21–30: 3.817.121.**
Severity batch ini: 3 Critical, 5 High, 2 Medium.
Waktu analisis: seluruh batch 21–30 dikerjakan dalam satu sesi subagent
16 Nov 2026 malam (~1 jam, termasuk debug 4 kegagalan harness).
Semua root cause diidentifikasi sendiri dari membaca kontrak + factory;
**tidak ada writeup/blog yang dibaca, tidak ada file test repo yang
dibuka.**

### Catatan kejujuran (wajib dibaca)

1. **Level 21–30 MURNI 10/10.** Tidak ada file test repo yang dibuka,
   tidak ada writeup yang dibaca. Empat kegagalan awal adalah kegagalan
   harness/debug, bukan hipotesis root cause yang salah:
   (a) DoubleEntryPoint: `vm.prank` habis dimakan panggilan view
   `instance.forta()` (diperbaiki: baca alamat dulu, baru prank);
   (b) AlienCodex: slot storage salah tebak karena packing lintas
   inheritance (diperbaiki: probe `vm.load` per slot + indeks dari
   `keccak256(1)`); (c) Denial: `assert(false)` di Solidity 0.8
   adalah revert dengan refund gas, bukan INVALID (diperbaiki: loop
   tak berujung dengan SSTORE); (d) MagicNum: `testInit` memanggil
   `validateInstance` saat solver masih `address(0)` (diperbaiki:
   assert `solver() == address(0)` saja).
2. **AlienCodex adalah debug tersulit di seluruh benchmark Ethernaut
   30 level.** Tebakan layout storage yang "jelas" ternyata salah
   karena packing; buktinya hanya didapat dari probing `vm.load`
   per slot. Pelajaran: jangan pernah percaya tebakan layout — ukur.
3. **Denial adalah level dengan gas testSolve tertinggi (1,2 juta)**
   karena test-nya benar-benar membakar ~984k gas — bukan artefak,
   melainkan inti exploit-nya.
4. **Severity jujur:** Denial dan MagicNum tetap Medium meski
   "menarik" — Denial tidak mencuri dana (DoS), MagicNum bukan
   kerentanan dana. Tidak ada yang dibesar-besarkan.

### Pola baru vs level 1–20 + DVD (yang belum dimiliki benchmark sebelumnya)

- Override ERC20 selektif yang tidak lengkap (NaughtCoin).
- Sistem monitoring (Forta detection bot) sebagai permukaan
  exploit/pertahanan (DoubleEntryPoint).
- Control flow berbasis tipe custom error / try-catch (GoodSamaritan).
- Underflow panjang array dinamis di Solidity 0.5 (AlienCodex).
- **Storage packing lintas inheritance** yang menyesatkan analisis
  layout (AlienCodex) — temuan debug terpenting batch ini.
- Gas griefing + aturan EIP-150 63/64 + semantik `assert` Solidity 0.8
  (Denial).
- Fungsi `view` yang stateful antar panggilan dalam satu transaksi
  (Shop).
- Bytecode EVM rakitan tangan / kontrak minimal 10 byte (MagicNum).
- Hardcoded offset calldata / kebingungan layout ABI (Switch).
- Unchecked ERC20 return value → stake hantu + insolvensi akuntansi
  (Stake).

### Pola yang sudah dikenal (konfirmasi, bukan penemuan)

- Constructor salah eja (GatekeeperThree) — sejalan dengan Fallout (#2).
- Password di storage slot (GatekeeperThree) — sejalan dengan Vault (#8).
- Gerbang `tx.origin` + prank 2 argumen (GatekeeperThree) — sejalan
  dengan Telephone (#4) + pelajaran fase H.
- Owner harus kontrak yang menolak ETH (GatekeeperThree) — sejalan
  dengan King (#9, push-payment).

### Pelajaran untuk perburuan bounty nyata

1. **Jangan tebak layout storage — ukur.** Packing lintas inheritance
   (AlienCodex) membuktikan tebakan "jelas" bisa salah total. Saat
   audit, verifikasi slot dengan `vm.load` / `cast storage` sebelum
   menulis PoC yang bergantung pada slot.
2. **Keccak-256 ≠ SHA3-256.** `hashlib.sha3_256` Python adalah NIST
   SHA3 (padding berbeda) — hasilnya salah untuk slot array. Pakai
   `pycryptodome` (`Crypto.Hash.keccak`) atau Foundry.
3. **Solidity 0.8 mengubah semantik `assert`.** `assert(false)` adalah
   revert dengan refund gas, bukan INVALID yang menghabiskan gas.
   Exploit gas-griefing harus benar-benar membakar gas, dan hitung
   aturan 63/64 EIP-150: sisa gas pemanggil sering tidak cukup untuk
   menyelesaikan fungsi.
4. **`vm.prank` hanya satu panggilan — termasuk panggilan view.**
   Baca semua alamat yang dibutuhkan dulu, baru prank.
5. **`view` ≠ konstan.** Fungsi view bisa membaca state yang berubah
   di tengah transaksi (Shop) — harga yang dibaca dua kali bisa
   berbeda. Audit harus curiga pada pemanggilan berulang ke fungsi
   yang sama dalam satu transaksi.
6. **Unchecked return value masih hidup.** Stake adalah pola klasik
   yang tetap muncul di kode nyata — `transferFrom` yang gagal diam-diam
   tapi akuntansi tetap jalan = insolvensi.
7. **Parsing calldata manual yang mengasumsikan offset tetap adalah
   bug** (Switch). Bila kontrak membaca calldata dengan offset
   hardcode, uji dengan offset berbeda.
8. **Salin PoC ke repo SEGERA setelah lolos** (pelajaran fase F) —
   diterapkan di fase ini: 10 file solusi sudah di `benchmarks/`
   sebelum laporan ini ditulis.
9. **Baca `validateInstance` dulu** — kondisi sukses resmi tiap level
   ada di factory (mis. Stake menuntut T > B DAN U == 0 DAN staker;
   Denial menuntut revert dengan gas 1.000.000). Membacanya mencegah
   salah tafsir tujuan.

---

## RINGKASAN AKHIR — BENCHMARK ETHERNAUT SELESAI (30 LEVEL)

**Skor total: 30/30.**

| Batch | Level | Skor | Severity | Gas testSolve total |
|---|---|---|---|---|
| Fase G | 1–10 | 10/10 | 2 Critical, 6 High, 2 Medium | 1.302.428 |
| Fase H | 11–20 | 10/10 | 5 Critical, 4 High, 1 Medium | 9.050.831 |
| Fase I | 21–30 | 10/10 | 3 Critical, 5 High, 2 Medium | 3.817.121 |
| **Total** | **1–30** | **30/30** | **10 Critical, 15 High, 5 Medium** | **14.170.380** |

**Verifikasi segar akhir:** `forge test` di `/tmp/ethernaut-work` —
**60 tests passed, 0 failed** (30× `testInit` + 30× `testSolve`).
Seluruh 30 file solusi ada di `benchmarks/ethernaut-*-solution.t.sol`.

### Catatan kejujuran akhir (seluruh benchmark)

- **29/30 murni + 1 sebagian dibantu.** Level #1 Fallback (fase G)
  terkontaminasi: file test repo sempat dibaca sebelum PoC ditulis.
  Level 2–30 semuanya murni (root cause dari membaca kontrak +
  factory saja, tanpa writeup).
- **Tidak ada level yang BLOKIR.** Aturan SMART SKIP tidak pernah
  terpicu di Ethernaut — tidak ada level yang gagal setelah 3
  pendekatan berbeda. Yang ada hanya kegagalan harness (Motorbike
  EIP-6780, prank `tx.origin`, cast payable, prank habis view,
  slot packing, semantik `assert` 0.8, `validateInstance` di
  `address(0)`).
- **Semua PoC dieksekusi dan PASS dengan bukti segar** — tidak ada
  klaim tanpa test.

### Level tersulit (subjektif, berdasarkan waktu debug)

1. **AlienCodex (#25)** — packing storage lintas inheritance menyesatkan
   seluruh analisis slot; butuh probing `vm.load` + koreksi Keccak.
2. **GatekeeperOne (#17)** — brute-force gas (5.314.837 gas testSolve,
   tertinggi di seluruh benchmark).
3. **Motorbike (#14)** — EIP-6780: selfdestruct pasca-Cancun hanya
   menghapus kode bila kontrak dibuat di transaksi yang sama.
4. **Stake (#30)** — butuh penalaran multi-aktor (staker kedua) +
   dua cacat berlapis.
5. **Denial (#26)** — semantik `assert` 0.8 + aturan gas 63/64.
6. **SafeMiners (DVD #13, di luar Ethernaut)** — tetap yang tersulit
   secara keseluruhan (pencarian private key gagal semua → prediksi
   alamat CREATE).

### Pola tersulit / paling berharga untuk perburuan bounty nyata

- **Logic/business-logic berantai** (PuzzleWallet 3 langkah, Motorbike
  init→upgrade→selfdestruct, Stake 2 cacat + 2 aktor) — pola tunggal
  jarang cukup; kemenangan datang dari merangkai.
- **Interaksi dengan perilaku EVM modern** (EIP-6780, aturan gas 63/64,
  semantik `assert` 0.8) — PoC yang ditulis untuk EVM lama bisa gagal
  diam-diam di chain modern. Selalu periksa `evm_version` target.
- **Storage layout sebagai permukaan serangan** (tabrakan proxy,
  packing lintas inheritance, underflow array) — layout yang salah
  dibaca = PoC yang salah.
- **Unchecked return value + ordering state** (Stake) — pola klasik
  yang tetap membayar di audit nyata.
- **Harga dari state yang bisa dimanipulasi** (Dex AMM tanpa TWAP,
  Puppet oracle spot) — pola yang sama muncul di DVD dan Ethernaut.

### Pelajaran utama untuk perburuan bounty nyata

1. **Baca kode, bukan writeup.** 29/30 level diselesaikan hanya dari
   membaca kontrak + factory. Kemampuan membaca kode adalah
   pengali terbesar — bukan menghafal pola.
2. **Ukur, jangan tebak.** Slot storage, gas, Keccak — semua yang
   bisa diukur harus diukur sebelum PoC ditulis.
3. **Harness adalah setengah pekerjaan.** Mayoritas waktu yang hilang
   di benchmark ini adalah kegagalan harness Foundry (prank, cast,
   EIP-6780, slot), bukan logika exploit. Kuasai alat sebelum
   berburu.
4. **Severity jujur menghemat kredibilitas.** DoS tanpa pencurian dana
   = Medium; teka-teki tanpa dana = Medium. Panel bounty menghargai
   penilai yang tidak membesar-besarkan.
5. **Salin PoC ke tempat permanen SEGERA setelah lolos** — VM restart
   fase F menghapus 3 solusi; sejak itu tidak ada lagi solusi yang
   hilang.
6. **Integrasikan pola ke skill.** Pola baru dari benchmark ini
   (AMM tanpa TWAP, tabrakan storage proxy, init UUPS, gerbang
   gas/extcodesize, EIP-6780, prediksi CREATE, randomness,
   `tx.origin`, storage layout, push-payment DoS, unchecked return
   value, stateful view, hardcoded calldata offset, gas griefing)
   adalah bahan revisi skill `bounty-hunter` / `sc-audit` /
   `invariant-testing` berikutnya.

### Langkah berikut

- Integrasikan pola baru dari Ethernaut 21–30 (storage packing,
  gas griefing + 63/64, unchecked return value, stateful view,
  hardcoded calldata offset, bytecode minimal) ke skill
  `bounty-hunter` / `sc-audit` / `invariant-testing` pada revisi
  berikut.
- Benchmark berikutnya yang dipertimbangkan: Capture The Ether
  (atau kembali ke perburuan bounty DeFi nyata dengan kemampuan
  yang sudah terukur ini).

**Baseline Ethernaut 21–30 SELESAI — 10/10, terverifikasi segar.**
**Benchmark Ethernaut SELESAI PENUH — 30/30.**
Seluruh file solusi ada di `benchmarks/ethernaut-*-solution.t.sol`
(30 file total untuk level 1–30).
