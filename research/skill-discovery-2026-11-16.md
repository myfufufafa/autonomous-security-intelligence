# Skill Discovery — Pass 1 (IDENTIFY + SEARCH)

**Misi:** Autonomous Bounty Intelligence & Skill Evolution (perintah Mas, 16 Nov 2026 ~21:05 WIB)
**Tanggal:** 16 November 2026
**Siklus:** IDENTIFY + SEARCH saja (STUDY / PRACTICE / TEST menyusul di pass 2)
**Status:** KANDIDAT SAJA — tidak ada satu pun yang diklaim sudah dikuasai, diadopsi, atau diinstal.

## 1. Konteks: gap yang harus ditutup

Hunt Sparklend (16 Nov 2026) menghasilkan **0 temuan submittable dari 15 hipotesis + 71 PoC test**.
Metode yang dipakai: pola-kenal (pattern matching kelas bug yang sudah dikenal) + PoC fork
mainnet + 7-Question Gate. Semua kandidat gugur di gate: dampak tidak ada, butuh aksi
governance, butuh modal raksasa tanpa profit, atau duplikat temuan audit.

**Pelajaran:** pola-kenal + PoC fork tidak cukup. Yang dicari pass ini adalah metode yang
menemukan kerentanan **LOGIC / BUSINESS-LOGIC yang terlewat researcher lain**: chained
vulnerabilities, economic exploits, asumsi yang bisa dilanggar, edge case di luar test
developer — yaitu bug yang hanya muncul dari urutan interaksi (state), bukan dari satu
panggilan fungsi.

**Konteks bounty saat ini:** TIDAK ADA bounty DeFi yang workable (Sparklend CLOSED,
CoW BLOCKED KYC+fee, Beanstalk PAUSED; laporan Safe H1+C1 menunggu panel). Karena itu
ranking di bawah ini **bukan** berdasarkan relevansi bounty aktif, melainkan: potensi
menemukan bug (bobot 2x) + testabilitas lokal + manfaat jangka panjang + kualitas sumber.

**Aturan keras yang dipatuhi di pass ini:**
- RESEARCH ONLY — tidak install apa pun, tidak jalankan script/kode eksternal apa pun,
  tidak clone repo berisi payload executable. Semua verifikasi via `gh search` / `gh repo view`
  (API read-only) dan `browser.search` / `browser.open` (baca README/docs).
- Hanya GRATIS + lisensi terbuka **MIT/Apache** yang masuk tabel ranking. Lisensi lain
  (AGPL/GPL/CC-BY-SA) dicatat di bagian "Ditolak / Terblokir lisensi" — bukan karena
  kualitasnya rendah, tapi karena aturan vetting misi mensyaratkan MIT/Apache.
- Tanpa secret apa pun. Tidak ada API key, token, atau kredensial yang disentuh.
- Semua klaim vendor (mis. "menemukan 126 vuln vs Echidna 0") dicatat sebagai
  **klaim yang belum terverifikasi** — harus dibuktikan sendiri di pass TEST.

## 2. Yang sudah dimiliki (tidak dicari lagi — anti-duplikasi)

Skill keamanan yang sudah diadopsi misi Skill Engineering dan relevan: `web3-audit`,
`meme-coin-audit`, `bounty-hunter` (skill utama hunt Sparklend), `foundry-workflow`
(mencakup **dasar** invariant testing: handler + ghost variable), `oracle-integration`,
`oracle-safety`, `defi-expert`, `fixed-point-rounding`, `pausable-circuit-breaker`,
`triage-validation`, `security-audit`, `doubt-driven-development`, `zero-hallucination-coder`,
`systematic-debugging`, `probabilistic-forecaster`, `backtest-expert`, `skill-security-auditor`.

Yang sudah dievaluasi sebelumnya dan TIDAK dicari ulang: `smart-contract-audit`
(Viprasol — ~70% overlap dengan web3-audit + bounty-hunter, ditunda batch 6),
`mev-slippage-protection` (tercakup defi-expert), `invariant-testing` dasar (tercakup
foundry-workflow — pass ini mencari lapisan **lanjutannya**, bukan duplikatnya),
Slither (sudah dipakai di hunt Safe + Sparklend).

## 3. Tabel ranking kandidat (MIT/Apache saja)

Skor = 2×Potensi menemukan bug + Testabilitas + Manfaat jangka panjang + Kualitas sumber.
Tiap kriteria 1–5, total maksimal 25.

| # | Kandidat | Sumber | Lisensi | Kemampuan baru yang ditambahkan | Menutup gap Sparklend | Testabilitas lokal | Skor |
|---|---|---|---|---|---|---|---|
| 1 | **Invariant testing lanjut (Foundry)** | Foundry Book + mystic0xx invariant-testing SKILL.md | Apache-2.0 / MIT | Handler + ghost variable tingkat lanjut; coverage-guided fuzzing; storage-aware input; time/block delay; invariant optimization (maksimalkan metrik: worst-case slippage, rounding error terbesar) | Langsung: eksplorasi ruang state secara sistematis — menemukan asumsi yang dilanggar lewat URUTAN panggilan, bukan satu panggilan | TERTINGGI — Foundry 1.9.0 sudah terinstal, nol dependensi baru | **24/25** (P5 T5 J5 K4) |
| 2 | **ItyFuzz** | https://github.com/fuzzland/ityfuzz | MIT | Hybrid fuzzer: symbolic/concolic execution + coverage-guided fuzzing; integrasi Foundry invariant test; flashloan + liquidation support; exploit generation otomatis (precision loss, overflow, fund stealing, Uniswap pair misuse); reentrancy; chain forking; decompilation | Langsung: menemukan jalur multi-panggilan + flashloan-assisted yang PoC satu-tx tidak bisa lihat; concolic execution menutup celah yang fuzzing murni lewatkan | TINGGI — jalan di atas invariant test Foundry yang sudah ada; BUTUH Rust toolchain + audit jalur install (README memakai `curl \| bash` — DILARANG aturan kami) | **23/25** (P5 T4 J5 K4) |
| 3 | **DeFiHackLabs** | https://github.com/SunWeb3Sec/DeFiHackLabs | Apache-2.0 | Replay insiden hack DeFi nyata sebagai Foundry fork test; anatomi economic exploit + root cause per insiden; template PoC dari serangan sungguhan | Tidak langsung (korpus belajar, bukan finder) — tapi mengajarkan pola economic exploit NYATA yang tidak ada di checklist pola-kenal | TINGGI — Foundry 1.9.0 + public RPC untuk fork; baca dulu tiap test sebelum jalan | **23/25** (P4 T5 J5 K5) |
| 4 | **aeon sc-audit SKILL.md** | https://github.com/aeonfun/aeon/blob/HEAD/skills/sc-audit/SKILL.md | MIT | Metodologi audit invariant-first: modelkan invariant protokol + trust boundary DULU, lalu berburu jalur yang mematahkannya; verifikasi adversarial; buktikan dengan fuzzer; disclosure operator-gated | Langsung: disiplin penalaran yang hilang di Sparklend — kami berburu pola, skill ini memaksa berburu PELANGGARAN INVARIANT + self-check adversarial | TINGGI — SKILL.md metodologi (73 KB); pakai Slither best-effort + fuzzer yang sudah ada; mesin otomasi aeon (GitHub Actions, API key, Telegram/Discord) TIDAK diadopsi | **22/25** (P5 T4 J4 K4) |
| 5 | **Korpus laporan Code4rena + Cantina + Rekt DB** | Situs resmi Code4rena / Cantina (laporan kontes publik) + Rekt database (riwayat exploit) | Publik, bebas dibaca (bukan repo kode) | "Belajar dari temuan yang menang": baca terstruktur laporan kontes → bangun pustaka pola logic/business-logic bug yang TERBUKTI lolos triage dan dinilai; framing severity + impact dari temuan nyata | Langsung: mengajarkan seperti apa temuan logic yang MENANG kontes — termasuk chained bug dan framing dampak | TERTINGGI — hanya membaca + menulis catatan pola sendiri; tanpa tool | **21/25** (P4 T5 J4 K4) |
| 6 | **Damn Vulnerable DeFi (+ port Foundry)** | https://github.com/OpenZeppelin/damn-vulnerable-defi ; port Foundry: https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry | MIT / MIT | Benchmark lab: 10+ tantangan (flash loan, oracle, AMM, lending, governance) untuk mengukur kemampuan secara objektif | Tidak langsung (benchmark, bukan finder) — tapi memberi ALAT UKUR: akurasi identifikasi, root cause, false positive, kualitas PoC, waktu analisis (sesuai misi §6) | TINGGI — Foundry; port Foundry tersedia (515★) | **21/25** (P3 T5 J5 K5) |
| 7 | **Secureum mind map** | https://github.com/x676f64/secureum-mind_map | MIT | Knowledge base audit: peta metodologi audit Secureum Epoch 0 (proses audit, taksonomi kerentanan, EVM) — struktur threat-modeling yang sistematis | Tidak langsung (pengetahuan, bukan finder) — memberi kerangka threat modeling agar analisis tidak acak | TERTINGGI — dokumen; tanpa tool | **19/25** (P3 T5 J4 K4) |
| 8 | **Mythril** | https://github.com/ConsenSys/mythril | MIT | Symbolic execution (laser) + taint analysis + cek SWC; eksplorasi jalur simbolik menemukan edge case yang fuzzing lewatkan (nilai input spesifik pemicu cabang kode) | Langsung tapi generasi lama: symbolic murni lebih lambat dari concolic fuzzer; pelengkap, bukan pengganti, invariant testing | SEDANG — tool Python, butuh solc + laser; lebih berat dari Foundry | **18/25** (P4 T3 J3 K4) |

## 4. Detail per kandidat

### 4.1 #1 — Invariant testing lanjut (Foundry)
- **Sumber:** Foundry Book (Apache-2.0, 967★, update 12 Nov 2026) — bab Invariant Testing;
  `mystic0xx/awesome-solidity-smart-contracts-skills` SKILL.md invariant-testing (MIT, sumber
  yang sama dengan skill batch 5–6 yang sudah diadopsi).
- **Kenapa #1:** satu-satunya kandidat dengan testabilitas maksimal (nol install baru) DAN
  potensi tertinggi. `foundry-workflow` yang kami miliki hanya mencakup dasar handler +
  ghost variable. Yang BARU di sini: fitur Foundry v1.3+ (coverage-guided fuzzing,
  storage-aware input) dan v1.7+ (`check_interval`, `max_time_delay` / `max_block_delay`
  untuk logika bergantung waktu — vesting, TWAP, cooldown — dan invariant optimization
  untuk memaksimalkan metrik seperti worst-case slippage / rounding error terbesar).
  Plus pola invariant DeFi spesifik: lending health factor, ERC-4626 share arithmetic,
  AMM tick math.
- **Hubungan dengan Sparklend:** semua 7 kandidat Sparklend adalah soal STATE dari waktu ke
  waktu (rasio oracle, akrual bunga, LTV/LT). Invariant testing dengan time-delay adalah
  metode yang dirancang untuk menemukan persis jenis bug itu.
- **Yang harus diverifikasi sebelum adopsi:** (a) fitur v1.3/v1.7 benar-benar ada di
  Foundry 1.9.0 terinstal (`forge --help` / uji cepat); (b) audit SKILL.md mystic0xx
  dengan checklist skill-security-auditor; (c) tulis 1 invariant test contoh pada
  kontrak lokal dan buktikan ia berjalan + gagal dengan benar saat invariant dilanggar.

### 4.2 #2 — ItyFuzz
- **Sumber:** https://github.com/fuzzland/ityfuzz — MIT, 1.122★, update 12 Nov 2026,
  1.175 commit, 19 release. Dibangun di atas LibAFL. Paper ACM tersedia.
- **Kemampuan kunci (terverifikasi dari README, dibaca 16 Nov 2026):** hybrid fuzzer
  (symbolic execution + fuzzing) untuk EVM + MoveVM, onchain dan offchain; menjalankan
  Foundry invariant test (`ityfuzz evm -m test/Invariant.sol:Invariant -- forge test`);
  flashloan support (asumsi attacker punya dana tak terbatas); liquidation support;
  reentrancy support; exploit generation otomatis (>80% hack lama diklaim bisa
  digenerate exploitnya — KLAIM VENDOR, belum terverifikasi); chain forking;
  decompilation untuk kontrak tanpa source.
- **Kenapa #2, bukan #1:** kekuatannya lebih besar dari Foundry murni, tapi biaya
  adopsi lebih tinggi (Rust toolchain; jalur install default `curl -L https://ity.fuzz.land/ | bash`
  **DILARANG** aturan keamanan kami — adopsi hanya via build dari source atau binary
  release terverifikasi + hash check). Logisnya: bangun invariant yang bagus dulu (#1),
  lalu ItyFuzz yang menjalankannya dengan concolic execution.
- **Yang harus diverifikasi sebelum adopsi:** (a) audit jalur install + apa yang
  dikirim ke jaringan (fuzzer mengambil data on-chain via RPC — wajar; pastikan tidak
  ada telemetri/exfil lain); (b) uji pada 1 kontrak rentan lokal yang sudah dikenal
  (level DVD) dan bandingkan hasil vs Foundry murni; (c) konfirmasi Rust tersedia /
  bisa diinstal aman; (d) catat: contoh di README menyertakan API key Etherscan
  vendor sebagai contoh — JANGAN pernah pakai key contoh itu; pakai RPC publik saja.

### 4.3 #3 — DeFiHackLabs
- **Sumber:** https://github.com/SunWeb3Sec/DeFiHackLabs — Apache-2.0, 6.845★,
  update 15 Nov 2026. Deskripsi repo: "Reproduce DeFi hacked incidents using Foundry."
- **Isi:** puluhan insiden hack DeFi nyata yang direproduksi sebagai Foundry fork test —
  tiap insiden = studi kasus root cause + PoC kerja dari serangan sungguhan.
- **Kenapa #3:** menutup gap "pola-kenal" dengan cara yang benar: bukan menghafal
  checklist, tapi mempelajari ANATOMI serangan ekonomi nyata (bagaimana flash loan +
  manipulasi harga + rounding digabungkan menjadi satu exploit). Ini bahan PRACTICE
  terbaik untuk siklus belajar §3.
- **Yang harus diverifikasi sebelum adopsi:** (a) baca tiap incident test sebelum
  dijalankan (fork test mengeksekusi kode exploit secara lokal — aman di EVM lokal,
  tapi baca dulu); (b) pastikan tidak ada panggilan jaringan selain RPC fork publik;
  (c) pilih 3–5 insiden yang paling relevan dengan kelas lending/AMM/oracle untuk
  dipelajari dulu, jangan semua sekaligus.

### 4.4 #4 — aeon sc-audit SKILL.md
- **Sumber:** https://github.com/aeonfun/aeon/blob/HEAD/skills/sc-audit/SKILL.md —
  MIT, file 73.482 byte, repo aeonfun/aeon 794★, update 15 Nov 2026.
- **Isi (terverifikasi dari ringkasan SKILL.md):** audit mendalam repo smart contract
  ATAU kontrak live by address (ambil verified source dari block explorer/Sourcify);
  modelkan invariant protokol + trust boundary DULU; jalankan Slither (best-effort);
  lalu agentic pass berburu jalur yang mematahkan tiap invariant; triage; verifikasi
  adversarial; buktikan dengan fuzzer; disclosure operator-gated (tidak pernah
  auto-file). Jujur soal kelemahan Slither: lemah pada access control, invariant
  protokol, oracle/price manipulation, rounding, upgradeability storage collision,
  cross-contract reentrancy — persis kelas yang menguras dana.
- **Kenapa #4:** ini metodologi penalaran, bukan tool. Disiplin "invariant dulu, baru
  berburu" adalah yang tidak kami lakukan di Sparklend (kami berburu pola, lalu cek
  dampak). Skill ini juga punya mekanisme adversarial self-check yang sejalan dengan
  gate verifikasi kami.
- **Yang harus diverifikasi sebelum adopsi:** (a) baca PENUH file 73 KB + audit dengan
  checklist skill-security-auditor (cari exfil, prompt injection, instruksi berbahaya);
  (b) HANYA adopsi metodologi — buang mesin otomasi aeon (GitHub Actions, API key
  Etherscan/Resend, routing Telegram/Discord/email); (c) adaptasi ke Bahasa Indonesia,
  tanpa referensi Claude Code; (d) verifikasi main chat sebelum dinyatakan dipakai.

### 4.5 #5 — Korpus laporan Code4rena + Cantina + Rekt DB
- **Sumber:** situs resmi Code4rena dan Cantina (laporan kontes audit publik) +
  Rekt database (riwayat exploit dengan root cause). Bukan repo kode — tidak ada
  lisensi yang perlu diverifikasi untuk MEMBACA. (Tautan diverifikasi saat STUDY.)
- **Isi/metode:** baca terstruktur laporan kontes → ekstrak pola logic/business-logic
  bug yang TERBUKTI menang (lolos triage juri, dinilai severity) → bangun pustaka pola
  sendiri di `vulnerability-patterns/` + catat framing severity/impact dari temuan nyata.
- **Kenapa #5:** satu-satunya sumber yang menunjukkan seperti apa temuan logic yang
  MENANG di dunia nyata — termasuk chained bug dan cara membingkai dampak agar
  dinilai High/Critical. Sparklend mengajarkan: temuan kami gugur bukan karena salah,
  tapi karena dampak tidak terbukti. Korpus ini mengajarkan pembuktian dampak.
- **Yang harus diverifikasi sebelum adopsi:** tidak ada adopsi tool — hanya metode
  membaca. Pastikan laporan yang dibaca adalah laporan FINAL (bukan draft) dan catat
  sumber + tanggal tiap pola.

### 4.6 #6 — Damn Vulnerable DeFi (+ port Foundry)
- **Sumber:** https://github.com/OpenZeppelin/damn-vulnerable-defi — MIT, 759★,
  update 12 Nov 2026. Port Foundry: https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry
  — MIT, 515★, update 11 Nov 2026.
- **Isi:** 10+ tantangan keamanan DeFi (flash loan, oracle, AMM, lending, governance)
  — standar benchmark komunitas untuk kemampuan audit.
- **Kenapa #6:** misi §6 menuntut benchmark internal (Ethernaut / DVD / Capture The
  Ether). DVD adalah yang paling siap untuk Foundry 1.9.0 (ada port Foundry-nya) dan
  langsung mengukur: akurasi identifikasi, root cause, false positive, kualitas PoC,
  ketepatan severity, waktu analisis.
- **Yang harus diverifikasi sebelum adopsi:** (a) uji port Foundry berjalan di
  Foundry 1.9.0 (bukan Hardhat); (b) bedakan tantangan yang masih relevan dengan
  pola DeFi modern vs yang sudah usang.

### 4.7 #7 — Secureum mind map
- **Sumber:** https://github.com/x676f64/secureum-mind_map — MIT, 1.898★, update
  15 Nov 2026. Repositori sentral coursework + kuis Secureum Epoch 0, cross-referenced.
- **Isi:** peta metodologi audit Secureum (proses audit, taksonomi kerentanan, EVM)
  — kerangka threat-modeling yang sistematis.
- **Kenapa #7:** memberi struktur agar analisis tidak acak: dari pemetaan arsitektur →
  identifikasi attack surface → threat modeling → pengujian. Berguna sebagai
  knowledge-base di `knowledge-base/`.
- **Yang harus diverifikasi sebelum adopsi:** (a) konten memang coursework Epoch 0
  (materi edukasi publik); (b) periksa link mati / konten usang.

### 4.8 #8 — Mythril
- **Sumber:** https://github.com/ConsenSys/mythril — MIT (terverifikasi via API GitHub),
  4.278★, update 15 Nov 2026.
- **Isi:** symbolic execution (laser-ethereum) + taint analysis + cek SWC Registry.
  Menemukan edge case lewat eksplorasi jalur simbolik — nilai input spesifik yang
  memicu cabang kode tertentu.
- **Kenapa #8 (terendah):** generasi lama — symbolic murni lebih lambat dari concolic
  fuzzer (ItyFuzz) dan tidak punya flashloan/liquidation modeling. Pelengkap, bukan
  pengganti invariant testing. Tetap MIT + terawat, jadi layak sebagai kandidat cadangan.
- **Yang harus diverifikasi sebelum adopsi:** (a) kebutuhan Python + solc;
  (b) uji pada 1 kontrak contoh dan ukur waktu vs Foundry; (c) nilai tambah nyata
  di atas ItyFuzz sebelum dipakai rutin.

## 5. Ditolak / terblokir / ditunda (dengan alasan)

| Kandidat | Lisensi / status | Alasan |
|---|---|---|
| Halmos (a16z) | AGPL-3.0 | Symbolic testing untuk Foundry — secara teknis kandidat #1 untuk gap ini, tapi lisensi AGPL-3.0 bukan MIT/Apache → TIDAK bisa diadopsi sebagai skill/source. Metodologi symbolic testing-nya tetap bisa dipelajari dari docs. Keputusan pakai tool AGPL butuh persetujuan main chat/Mas. |
| Echidna (crytic) | AGPL-3.0 | Fuzzer property-based referensi (Trail of Bits), 3.198★ — terblokir lisensi. Perannya digantikan Foundry invariant testing + ItyFuzz. |
| Medusa (crytic) | AGPL-3.0 | Fuzzer coverage-guided (502★) — terblokir lisensi. Perannya digantikan ItyFuzz. |
| HEVM (argotorg) | AGPL-3.0 | Symbolic execution EVM — terblokir lisensi. |
| Aderyn (Cyfrin) | GPL-3.0 | Static analyzer Rust (809★) — terblokir lisensi. (Ekstensi VSCode-nya Apache-2.0, tapi itu bukan analyzer-nya.) |
| 4naly3er (Picodes) | GPL-3.0 | Static analysis untuk auditor (552★) — terblokir lisensi. |
| Building Secure Contracts (Trail of Bits, buku) | AGPL-3.0 | Pedoman + checklist audit (2,5K★) — terblokir lisensi sebagai adopsi verbatim. |
| Ethernaut (OpenZeppelin) | AGPL-3.0 (kode) | Wargame 2.348★ — kodenya AGPL, tapi situsnya bisa dipakai sebagai BENCHMARK tanpa mengadopsi kode. Status: benchmark saja, bukan skill. |
| trailofbits/skills | CC-BY-SA-4.0 | **Nilai tertinggi di antara yang terblokir** (8.229★): 11 sub-skill building-secure-contracts + property-based-testing skill. CC-BY-SA-4.0 bukan MIT/Apache → tidak bisa adopsi verbatim. Jalur yang mungkin: tulis-ulang metodologi dengan kata-kata sendiri (ide tidak berhak cipta) ATAU pengecualian aturan dari Mas. Butuh keputusan main chat. |
| bountyforge (hien) | Tidak diketahui | DITOLAK. Terlalu luas (web/API, CI/CD, LLM, infra — bukan fokus EVM logic); pola remote-fetch dari UPSTREAM mentah; menyentuh kategori yang ditolak permanen (credential-attack, cloud-pentest); menyebut "7-Question Gate" — terminologi internal kami — tanpa sumber yang jelas (amalgamasi tanpa vetting). |
| avaxskills audit (Eras256) | Apache-2.0 | DITUNDA — lisensi lolos, tapi Avalanche/Teleporter/Warp saja; relevansi rendah untuk bounty EVM mainnet. |
| Solodit (solodit_content) | Tanpa lisensi | DITUNDA — checklist audit agregator; repo konten tanpa field lisensi → tidak bisa diverifikasi. Perlu cek lisensi sebelum apa pun. |
| Viprasol smart-contract-audit | (sudah dievaluasi) | Bukan baru — sudah dievaluasi batch 6 (~70% overlap web3-audit + bounty-hunter), ditunda. |
| Slither | (sudah dimiliki) | Sudah dipakai di hunt Safe + Sparklend — bukan kandidat baru. |
| SmartBugs dataset | Tidak ditemukan | Pencarian GitHub tidak menemukan dataset konsolidasi yang meyakinkan — tidak ada kandidat. Korpus C4/Cantina/Rekt (#5) menggantikan peran ini. |
| Capture the Ether | Repo asli hilang | Repo `smarx/capture-the-ether` tidak lagi ter-resolve; jaringan Ropsten sudah deprecated 2023; situs mungkin tidak lagi bisa dimainkan penuh. Benchmark terdegradasi — utamakan DVD (#6) + situs Ethernaut. |

## 6. Rencana pass 2 (STUDY + PRACTICE + TEST)

Urutan yang diusulkan (bukan keputusan — adopsi butuh audit + verifikasi main chat):

1. **#1 Invariant testing lanjut** — STUDY Foundry Book + SKILL.md mystic0xx; PRACTICE:
   tulis invariant test (handler + ghost + time-delay) pada 1 protokol lending lokal;
   TEST: buktikan ia menangkap pelanggaran invariant yang sengaja disisipkan.
2. **#3 DeFiHackLabs** — STUDY 3–5 insiden (lending/AMM/oracle); PRACTICE: jalankan
   replay-nya, tulis ringkasan root cause + pola exploit ke `vulnerability-patterns/`.
3. **#2 ItyFuzz** — STUDY docs; audit jalur install; TEST pada level DVD yang sudah
   dikenal; bandingkan hasil vs Foundry murni (ukur: bug ditemukan, waktu, false positive).
4. **#4 aeon sc-audit** — baca penuh + audit keamanan; adaptasi metodologi
   (Bahasa Indonesia, tanpa mesin otomasi) sebagai skill kandidat.
5. **#6 DVD** — jadikan benchmark resmi: jalankan semua tantangan, catat baseline
   kemampuan (akurasi, root cause, false positive, kualitas PoC, waktu) di `benchmarks/`
   SEBELUM dan SESUDAH skill baru dipakai.
6. **#5 Korpus C4/Cantina/Rekt** — berjalan paralel: tiap minggu baca 2–3 laporan,
   ekstrak pola ke `vulnerability-patterns/`.

## 7. Catatan kejujuran

- Laporan ini adalah hasil IDENTIFY + SEARCH saja. **Tidak ada satu pun kandidat di
  atas yang sudah dipelajari mendalam, diuji, atau dikuasai.** Semua skor adalah
  penilaian awal berdasarkan dokumentasi + metadata repo (bintang, update terakhir,
  lisensi terverifikasi via API GitHub) — bukan hasil pengujian.
- Semua klaim vendor (khususnya ItyFuzz: "126 vuln vs Echidna 0", "exploit otomatis
  >80% hack lama") dicatat sebagai klaim, bukan fakta, sampai dibuktikan di pass TEST.
- Lisensi diverifikasi via GitHub API (`license.key`) pada 16 Nov 2026, kecuali
  dinyatakan lain. Lisensi bisa berubah — verifikasi ulang saat adopsi.
- Tidak ada instalasi, clone, atau eksekusi kode eksternal yang dilakukan di pass ini.
- Tidak ada secret, API key, atau data pribadi yang disentuh.

## 8. Sumber verifikasi (16 Nov 2026)

- GitHub API (`gh search repos`, `gh repo view`, `gh api`): lisensi + bintang + update
  terakhir untuk halmos, ityfuzz, aderyn, echidna, medusa, DeFiHackLabs,
  damn-vulnerable-defi, solodit, 4naly3er, secureum, hevm, mythril, aeon,
  trailofbits/skills, foundry-rs/book, ethernaut.
- `browser.open` README fuzzland/ityfuzz (dibaca penuh, 16 Nov 2026).
- `browser.search`: trailofbits/skills + building-secure-contracts (lisensi CC-BY-SA-4.0 /
  AGPL-3.0 terkonfirmasi dari beberapa sumber); Foundry Book invariant testing;
  SKILL.md audit (aeon sc-audit, avaxskills, Viprasol, bountyforge).
- Konteks internal: `MASTER_INSTRUCTION.md`, `tracker.md`, `~/workspace/research/
  spark-bugbounty/` (hipotesis + triage Sparklend), `~/workspace/your_files/
  skills-inventory.md` (skill yang sudah dimiliki).
