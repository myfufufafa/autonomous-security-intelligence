# aeon sc-audit — Audit Keamanan + Adaptasi

**Misi:** Autonomous Bounty Intelligence & Skill Evolution — Pass 2 fase C, item #4
**Tanggal:** 16 November 2026
**Sumber:** https://github.com/aeonfun/aeon/blob/HEAD/skills/sc-audit/SKILL.md
**Status:** AUDIT SELESAI — adaptasi ditulis sebagai skill KANDIDAT.
Adopsi formal menunggu verifikasi main chat (aturan misi).

## 1. Sumber (terverifikasi)

| Aspek | Hasil |
|---|---|
| Repo | `aeonfun/aeon` — lisensi **MIT** (terverifikasi via `gh api repos/aeonfun/aeon`, 16 Nov 2026) |
| File | `skills/sc-audit/SKILL.md` — **73.482 byte, 731 baris**, diunduh via raw.githubusercontent.com, dibaca PENUH (baris 1–731) |
| Update terakhir repo | 16 Nov 2026 (pushed 14:17 UTC) — aktif |
| Isi | Metodologi audit smart contract invariant-first + mesin otomasi aeon (target auto-select, fetch on-chain, Slither, fuzz Echidna/Medusa, disclosure via PVR/email/notifikasi) |

## 2. Audit keamanan (checklist skill-security-auditor)

### Langkah 1 — Baca penuh
Seluruh 731 baris dibaca (2 chunk). File adalah SATU dokumen `.md` —
tanpa skrip, tanpa biner, tanpa file tersembunyi, tanpa symlink,
tanpa `requirements.txt`/`package.json`, tanpa `.env`.

### Langkah 2 — Grep pola terlarang
Pola: `PRIVATE_KEY|SEED_PHRASE|*_API_KEY|ANTHROPIC_API_KEY|curl|sh|bash|
rm -rf /|telemetry|exfiltrat|Ignore previous instructions|You are now|
Skip safety checks|os.system|eval(|exec(|pickle.loads|yaml.load(|
socket.connect|requests.post|urllib|sudo|chmod 777|opus|sonnet|haiku|
claude|notify|secretcurl|RESEND|ETHERSCAN|BLOCKSCOUT`

Hasil: **0 pola CRITICAL.** Semua hit adalah referensi yang dijelaskan
di bawah (bukan secret, bukan perintah berbahaya):

| Hit | Penjelasan | Severity |
|---|---|---|
| `ETHERSCAN_API_KEY?`, `BLOCKSCOUT_API_KEY?`, `RESEND_API_KEY?`, `RESEND_FROM?`, `RESEND_REPLY_TO?` di frontmatter `requires:` | Deklarasi dependensi OPSIONAL mesin otomasi aeon. Bukan nilai secret — hanya nama placeholder. | Medium — bagian ini DIBUANG seluruhnya dalam adaptasi (tanpa kunci apa pun) |
| `*_API_KEY` di §S2b / §Network (12+ baris) | Prosa yang menjelaskan kunci dilewatkan lewat placeholder `./secretcurl` (`{ETHERSCAN_API_KEY}`) dan "never put the raw key on the command line". Tidak ada nilai kunci di mana pun. | Info — pola aman, tapi seluruh mekanisme ini DIBUANG dalam adaptasi |
| `claude -p` (§S3) + `CLAUDE.md` (§S9) | Referensi ke staging step dan file CLAUDE.md milik proyek aeon sendiri. Bukan dependensi `claude-api` / `ANTHROPIC_API_KEY`. | Info — DIBUANG dalam adaptasi (tanpa referensi Claude Code) |
| `./notify -f <file>` (§S9) | Mekanisme notifikasi aeon (Telegram/Discord/email). | Medium — DIBUANG dalam adaptasi (tanpa notifikasi otomatis) |
| `python3 -m pip install slither-analyzer / solc-select / crytic-compile` (§S3) | Instalasi tool standar (Slither dkk.) — best-effort, bukan `curl | bash`. | Info — tidak diadopsi (Slither sudah ada di venv kami; instalasi tidak perlu) |
| `curl -sL https://registry.npmjs.org/<pkg>` (§S5 provenance) | Fetch tarball upstream untuk diff SHA-256 file vendored. Tanpa pipe ke shell. | Info — metodologi provenance diadopsi sebagai penalaran; perintah fetch tidak diadopsi |
| TIDAK ADA | `PRIVATE_KEY`, `SEED_PHRASE`, `curl | sh/bash`, `rm -rf /`, telemetri/exfil, prompt injection ("Ignore previous instructions", "You are now", "Skip safety checks"), `os.system`, `eval(`, `exec(`, `pickle.loads`, `yaml.load`, `socket.connect`, `requests.post`, `urllib`, `sudo`, `chmod 777`, alias model opus/sonnet/haiku | — | — |

### Langkah 3 — Dependensi & struktur
- Tidak ada dependensi berbayar yang wajib. Slither/forge gratis;
  Echidna/Medusa adalah tool AGPL (tidak diinstal — metodologinya
  dipelajari terpisah di fase B misi).
- Tidak ada file > 1 MB (73 KB), tidak ada biner, tidak ada symlink.
- Lisensi MIT terverifikasi — lolos syarat lisensi misi.

### Langkah 4 — Pola yang tidak boleh diadopsi (aturan kami)
- Secret/kunci di env var: file MENDEKLARASIKAN kunci API sebagai
  dependensi opsional otomasi → **WARN, diremediasi** dengan membuang
  seluruh bagian yang bergantung kunci (lihat §3).
- Bukan humanizer, bukan perintah merusak, bukan tooling berbayar
  yang tidak bisa di-port.
- Tidak ada dependensi `claude-api` / `ANTHROPIC_API_KEY`.

### Langkah 5 — Verdict
**WARN → diremediasi → PASS untuk bagian metodologi.**
Satu temuan Medium (deklarasi kunci API untuk otomasi) — diremediasi
penuh dengan membuang seluruh mesin otomasi dari adaptasi. Bagian
metodologi (threat model, checklist, triage, verifikasi adversarial,
fuzz, laporan, disclosure) BERSIH: 0 temuan Critical/High, 0 karakter
tersembunyi, 0 BOM.

## 3. Yang DIBUANG dari adaptasi (mesin otomasi aeon)

- Pemilihan target otomatis (feed `github-trending`, ledger
  `sc-targets.json`, dedup `vuln-scanned.json`).
- Fork/clone repo otomatis (`gh repo fork`), fetch sumber on-chain
  (Etherscan V2 / Sourcify / Blockscout) — operator menyediakan target.
- Semua kunci API (Etherscan, Blockscout, Resend) + `./secretcurl`.
- Notifikasi (`./notify`), email (Resend), Telegram/Discord.
- Pengiriman disclosure otomatis (PVR GitHub, email) — diganti
  operator-gated: draf disiapkan, Mas/main chat yang memutuskan.
- Instalasi tool in-run (`pip install slither-analyzer` dkk.).
- Referensi `claude -p`, `CLAUDE.md`, `memory/` ledger, fixture
  aeon, template `${var}`.

## 4. Yang DIUBAH dalam adaptasi

| Aspek sumber | Adaptasi |
|---|---|
| Lengan fuzz Echidna/Medusa (AGPL, tidak diinstal) | **Foundry invariant test** (skill `invariant-testing`, sudah teruji fase A: 51.200 panggilan, tripwire bekerja) — termasuk witness reachability, negative control (mutan), dan cek budget benar-benar terpakai |
| Target auto-select / on-chain fetch | Operator menentukan target (repo lokal / sumber terverifikasi yang disediakan) |
| Disclosure otomatis (PVR/email) | Operator-gated, bounty-first (cari program live dulu; PVR hanya draf fallback) |
| Bahasa Inggris + referensi aeon internal | Bahasa Indonesia; tanpa referensi Claude Code / alias model |
| 731 baris | **349 baris** (dalam batas 150–350 panduan skill engineering) |

## 5. Verifikasi adaptasi (dilakukan 16 Nov 2026)

| Pemeriksaan | Hasil |
|---|---|
| Lokasi | `~/workspace/custom-skills/sc-audit/SKILL.md` |
| Baris | **349** (batas panduan 150–350) |
| Frontmatter | Ada (`name: sc-audit` + deskripsi Bahasa Indonesia) |
| Grep pola terlarang (pola yang sama dengan §2, + `notify`, `secretcurl`, `RESEND`, `ETHERSCAN`, `BLOCKSCOUT`) | **0 temuan** (grep exit 1) |
| Karakter zero-width / BOM | TIDAK ADA (cek byte-level Python) |
| Referensi kunci API | 0 — frasa yang dipakai "tanpa kunci API apa pun" (prosa, bukan pola `_API_KEY`) |
| Status | **KANDIDAT — adopsi formal menunggu verifikasi main chat** |

## 6. Nilai yang dibawa skill ini (bila diadopsi)

- Disiplin yang hilang di hunt Sparklend: **invariant dulu, baru berburu**
  (kami berburu pola, lalu cek dampak — skill ini memaksa berburu
  PELANGGARAN INVARIANT + self-check adversarial).
- Checklist v4-hook lengkap (kasus Cork $12 jt, Bunni $8,4 jt) + dua pola
  gate false-pass (unit-confusion `amountSpecified`, gate harga mentah
  vs `1.0`).
- Provenance dependensi vendored (diff SHA-256) — kelas backdoor yang
  tidak terlihat oleh explorer maupun reviewer.
- Lengan fuzz dengan hard gate + witness + negative control (mutan) —
  sejalan dengan temuan fase A (ghost/harness yang salah bisa memberi
  false positive/negative).
- Template laporan audit profesional + manifest cakupan (N/M kontrak,
  K invariant, tally verifikasi) — membuat audit berikutnya dapat
  dibandingkan run-over-run.

## 7. Batasan adaptasi

- Metodologi saja — belum diuji pada audit nyata (belum ada target
  bounty workable saat ini). Uji pertama yang natural: pakai skill ini
  pada tantangan DVD berikutnya atau audit protokol lokal.
- Fuzz arm memakai Foundry (bukan Echidna/Medusa) — trade-off yang
  disadari: tanpa concolic execution; ItyFuzz (#2 pass 1) adalah
  pelengkap bila nanti dibangun.
- Slither best-effort — bila build gagal, audit tetap jalan dari sumber.
