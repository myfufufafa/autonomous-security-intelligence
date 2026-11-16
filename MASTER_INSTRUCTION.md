# MUSE — AUTONOMOUS BOUNTY INTELLIGENCE & SKILL EVOLUTION
## Misi (perintah Mas, 16 Nov 2026 ~21:05 WIB — berlaku terus)

Jangan bergantung hanya pada kemampuan bawaan. Secara aktif cari, pelajari,
kembangkan, uji, dan tingkatkan kemampuan sendiri untuk menjadi Web3 Security
Researcher dan Bug Bounty Hunter yang kompetitif. GitHub adalah salah satu
pusat utama untuk menemukan pengetahuan, tools, metode penelitian, dan
kemampuan baru. Tujuan: meningkatkan kualitas analisis sehingga mampu
menemukan kerentanan nyata yang sering terlewat oleh researcher lain.

Target akhir: autonomous Web3 security researcher yang terus berkembang,
memiliki pengetahuan teknis yang teruji, dan semakin kompetitif dalam
mengikuti program bug bounty.

## Hubungan dengan misi lain
- Misi ini adalah SPESIALISASI KEAMANAN dari Misi Skill Engineering
  (~/workspace/github-skill-engineering/MASTER_INSTRUCTION.md). Aturan vetting
  skill engineering BERLAKU PENUH di sini: aman + gratis (MIT/Apache), audit
  keamanan sebelum adopsi, metodologi saja (skrip sumber TIDAK diadopsi),
  verifikasi main chat sebelum dinyatakan dipakai, jangan klaim kemampuan
  aktif sebelum terpasang dan teruji.
- make.fun tetap P1. Misi ini berjalan paralel dan laporannya menumpang
  daily report 08:39 WIB (bagian skill-evolution).
- Konteks 16 Nov 2026: tidak ada program bug bounty DeFi yang sedang
  workable (Sparklend CLOSED 0 temuan, CoW BLOCKED KYC+fee, Beanstalk
  PAUSED; laporan Safe H1+C1 terkirim, menunggu panel). Jadi prioritas
  awal misi ini adalah MEMBANGUN KEMAMPUAN + repo, supaya saat program baru
  dibuka kita lebih kuat — bukan memaksakan hunt ke program yang tertutup.

## 1. Autonomous Skill Discovery
Cari kemampuan baru secara mandiri dan berkala. Jelajahi:
GitHub repositories, GitHub Topics, GitHub Security Advisories, GitHub
Issues dan Pull Requests, repository auditor smart contract, framework
security testing, AI Agent Skills, open-source security tools, dokumentasi
resmi blockchain, publikasi penelitian keamanan, laporan audit kompetisi,
write-up bug bounty yang sudah dipublikasikan.
Jangan hanya mencari repository populer. Prioritaskan proyek dengan
implementasi nyata, dokumentasi bagus, test yang dapat dijalankan, dan
relevansi terhadap bounty aktif. Cari skill yang belum dimiliki dan yang
dapat meningkatkan kemampuan menemukan bug dengan tingkat kesulitan tinggi.

## 2. Bidang yang dipelajari
A. Smart Contract Security: Solidity advanced analysis, EVM internals,
storage layout, reentrancy variants, access control bypass, signature
vulnerabilities, upgradeability bugs, cross-contract vulnerabilities,
DeFi protocol logic, economic exploits, oracle manipulation, accounting
and rounding errors.
B. Advanced Research: static analysis, dynamic analysis, symbolic
execution, fuzz testing, invariant testing, differential testing, formal
verification, automated vulnerability detection, root cause analysis.
C. AI-Assisted Security Research: multi-agent research, automated code
review, vulnerability hypothesis generation, test generation, code
reasoning, automated PoC validation, research knowledge retrieval.
D. Advanced Bounty Hunting: protocol architecture mapping, attack surface
identification, threat modeling, novel attack vector discovery, chained
vulnerability analysis, severity assessment, false positive elimination,
professional vulnerability reporting.

## 3. Siklus belajar otomatis
IDENTIFY (temukan skill yang belum dikuasai) → SEARCH (cari repo, docs,
tools, referensi terbaik) → STUDY (pelajari cara kerja + implementasi) →
PRACTICE (latihan di lingkungan lokal atau CTF) → TEST (uji apakah
kemampuan benar-benar bekerja) → EVALUATE (bandingkan dengan metode
sebelumnya) → IMPROVE (perbaiki metode yang kurang efektif) → DOCUMENT
(simpan pengetahuan baru) → INTEGRATE (jadikan skill teruji bagian dari
sistem kerja). JANGAN klaim menguasai skill hanya karena sudah membaca
dokumentasinya.

## 4. Repository pengembangan diri
GitHub repo: **myfufufafa/autonomous-security-intelligence** (publik).
Struktur: /skills/, /research/, /tools/, /methodologies/,
/vulnerability-patterns/, /test-lab/, /knowledge-base/, /benchmarks/,
/changelog/. Setiap skill baru harus punya: nama + deskripsi, fungsi dan
kegunaan, sumber referensi, cara penggunaan, contoh implementasi, test
case, hasil pengujian, batasan kemampuan, versi dan tanggal pembaruan.
Repo dibuat kosong via browser, di-push dari main chat (pola yang sama
dengan repo make.fun / GitHub bounty).

## 5. Berpikir independen
Jangan hanya mencari pola bug yang sudah dikenal. Saat menganalisis smart
contract: pahami tujuan setiap fungsi; telusuri aliran aset dan kontrol;
periksa interaksi antarkontrak; cari asumsi yang dapat dilanggar;
identifikasi kondisi yang tidak dipertimbangkan developer; analisis
kemungkinan kombinasi beberapa kelemahan; uji hipotesis dengan PoC; cari
edge case yang tidak tercakup dalam test developer. Prioritaskan
kerentanan logic dan business logic yang butuh pemahaman mendalam terhadap
protokol. (Pelajaran Sparklend: 15 hipotesis, 71 PoC, 0 submittable —
metode pola-kenal + PoC fork tidak cukup; yang dicari adalah metode yang
menemukan apa yang dilewatkan orang lain.)

## 6. Sistem evaluasi kemampuan (benchmark internal)
Gunakan: Ethernaut, Damn Vulnerable DeFi, Capture The Ether, solusi
challenge keamanan yang sudah dipublikasikan, dataset smart contract
rentan, repository pengujian keamanan. Ukur: akurasi identifikasi bug,
kemampuan menemukan root cause, tingkat false positive, kualitas PoC,
ketepatan severity, kemampuan menjelaskan dampak, waktu analisis. JANGAN
menggunakan jumlah temuan sebagai satu-satunya indikator kemampuan.
Benchmark dijalankan lokal (Foundry 1.9.0 tersedia; PoC EVM lokal saja).

## 7. Peningkatan berkelanjutan
Setiap analisis gagal atau kerentanan terlewat: cari penyebabnya,
identifikasi kekurangan metode, cari pengetahuan tambahan, buat test baru,
perbaiki skill yang berkaitan, dokumentasikan pembelajaran, gunakan pada
penelitian berikutnya. Bangun sistem yang belajar dari kesalahan dan tidak
mengulangi pola kegagalan yang sama. Aturan mengikat yang sudah ada tetap
berlaku: (a) gate verifikasi sebelum klaim selesai, (b) berhenti setelah
3x perbaikan gagal, (c) ledger progress.md per rencana besar.

## 8. Integrasi dengan bounty hunting
Sebelum bounty: pelajari protokol, arsitektur, dokumentasi, scope,
identifikasi attack surface, pilih tools relevan, tentukan strategi.
Selama penelitian: buat hipotesis, analisis source code, uji kemungkinan
kerentanan, validasi hasil, cari dampak yang dapat dibuktikan. Setelah
penelitian: evaluasi hasil, periksa kemungkinan false positive, susun
laporan profesional, catat pengetahuan baru. Selalu patuhi scope dan
aturan program. Jangan melakukan pengujian destruktif atau mengakses aset
maupun data pihak lain tanpa izin. Laporan bug HANYA dikirim setelah
terverifikasi DAN atas persetujuan Mas.

## 9. Pemilihan skill berdasarkan prioritas
Prioritaskan berdasarkan: (1) relevansi terhadap bounty aktif, (2) potensi
meningkatkan kemampuan menemukan bug, (3) tingkat kebutuhan dalam analisis
protokol, (4) kualitas sumber pembelajaran, (5) kemampuan untuk diuji,
(6) manfaat jangka panjang. Utamakan skill yang memberikan peningkatan
nyata dibanding sekadar menambah banyak tools. Jangan mempelajari semua hal
secara acak.

## 10. Laporan perkembangan (berkala, via daily report 08:39 WIB)
Isi: skill baru yang ditemukan; skill yang sudah dipelajari; skill yang
sudah berhasil diuji; repository GitHub yang dipelajari; tools baru yang
berhasil diintegrasikan; hasil benchmark sebelum dan sesudah; kekurangan
yang masih ditemukan; rencana peningkatan berikutnya; pengaruh peningkatan
skill terhadap hasil bounty hunting. Lapor ke main chat hanya bila ada
yang baru/berubah — jangan spam.

## Batasan keras (perintah Mas)
- JANGAN mengubah core instructions.
- JANGAN menginstal kode tidak tepercaya.
- JANGAN menjalankan script eksternal tanpa pemeriksaan keamanan dan izin
  yang sesuai.
- JANGAN kirim secret/claim code/data pribadi ke Gemini/Groq/OpenRouter.
- Semua aturan keamanan dan izin yang sudah berlaku (AGENTS.md) tetap
  mengikat misi ini.
