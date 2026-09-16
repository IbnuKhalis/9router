# Agent Instructions — 9Router AI Gateway

> Berkas ini mendefinisikan standar operasional, arsitektur, dan batasan keamanan untuk agen AI dalam proyek **9Router**.
> Berkas ini dirujuk dan diselaraskan di `AGENTS.md` agar seluruh ekosistem AI coding (Antigravity, Claude Code, Cursor, Cline) mematuhi invariant yang sama.

Anda beroperasi sebagai **Orchestrator & System Implementer** untuk mengonfigurasi, menguji, dan memelihara 9Router sebagai AI Routing Layer terpusat bagi workstation lokal dan server VPS.

---

## 1. Arsitektur 3 Lapis (3-Layer Architecture)

Untuk menjamin determinisme dan reliabilitas tinggi, proyek ini memisahkan tanggung jawab ke dalam 3 lapisan:

```text
┌─────────────────────────────────────────────────────────┐
│ Layer 1: Directive (Apa yang harus dicapai)             │
│ • TODO.md (Master Roadmap & Status Pelacakan)           │
│ • docs/ & directives/ (SOP & panduan konfigurasi)       │
└────────────────────────────┬────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────┐
│ Layer 2: Orchestration (Pengambilan Keputusan)          │
│ • Agen AI (Antigravity) sebagai lem pemersatu           │
│ • Membaca direktif, validasi status, routing langkah    │
└────────────────────────────┬────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────┐
│ Layer 3: Execution (Eksekusi Deterministik)             │
│ • Docker Compose (docker-compose.yml, docker-compose.vps.yml) │
│ • Skrip pengujian CLI / curl / API verification         │
│ • Konfigurasi reverse proxy (Caddy) & variabel .env     │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Peran & Batasan 9Router dalam Ekosistem Pengguna

1. **Routing Layer, Bukan Pengganti Agen**:
   - 9Router bertindak murni sebagai **API Gateway & Model Router** (OpenAI-compatible endpoint `http://localhost:20128/v1` atau reverse proxy VPS).
   - Agen koding utama tetap **Antigravity** (serta tool CLI seperti Claude Code / Cursor). 9Router menyediakan endpoint LLM dengan token saver (RTK) dan smart fallback.
2. **Kemandirian Workspace**:
   - 9Router mengelola routing model dan API credentials; direktori proyek aplikasi lain (seperti `graduance`, `VPS-Monitor-Dashboard`, `Second-Brain`) tetap independen.

---

## 3. Invariant Lingkungan (Environment Invariants)

### 3.1 Workstation Lokal (Windows)
- **Sistem Operasi**: Windows 11 x64, CPU Intel i7-13700HX, GPU RTX 4050 6GB.
- **Terminal Shell**: PowerShell.
- **Aturan Sintaks PowerShell**:
  - Dilarang menggunakan operator `&&` (memicu `ParserError`). Gunakan titik koma `;` atau jalankan perintah secara terpisah.
  - Jangan gunakan perintah `cd` tersendiri; selalu tentukan path kerja secara eksplisit.
- **Docker Desktop**:
  - Container dijalankan via Docker Desktop (`decolua/9router:latest`).
  - Port default: `20128`. Dashboard web: `http://localhost:20128/dashboard`.
  - Persistensi data: bind mount atau named volume ke `/app/data` dengan `DATA_DIR=/app/data`.

### 3.2 Server Produksi (Oracle Cloud VPS)
- **Host Alias**: `vps-main` (IP: `129.225.1.91`, SSH user: `ubuntu`, key Ed25519 `~/.ssh/id_oracle_vps`).
- **Arsitektur CPU**: ARM64 (`VM.Standard.A1.Flex`, 2 OCPU Ampere, 12 GB RAM). Image Docker `decolua/9router` telah mendukung multi-platform `linux/arm64`.
- **Aturan Git sebagai Single Source of Truth**:
  - **Dilarang keras melakukan live-edit langsung di server VPS**. Semua perubahan konfigurasi dan berkas docker compose harus diuji secara lokal, di-commit, dan di-push ke GitHub.
- **Jaringan & Reverse Proxy**:
  - Bergabung ke Docker bridge eksternal: `proxy-network`.
  - Terhubung ke Caddy Reverse Proxy di `/opt/infrastructure/reverse-proxy/Caddyfile`.
  - Domain routing: `https://router.digitalneeds.my.id` (atau subdomain yang ditentukan di bawah `digitalneeds.my.id`).
  - SSL ditangani secara otomatis oleh Cloudflare Full/Strict + Caddy.

---

## 4. Standar Keamanan & Mitigasi Kerentanan

1. **Mitigasi CVE-2026-46339**:
   - Pastikan menggunakan image 9Router versi teranyar yang sudah menambal celah RCE unauthenticated.
   - Jalankan container dengan isolasi environment, pastikan token rahasia (`JWT_SECRET`, `INITIAL_PASSWORD`, `API_KEY_SECRET`) dikonfigurasi dengan aman, dan hindari mengekspos port mentah 20128 langsung ke internet publik tanpa autentikasi/reverse proxy.
2. **Perlindungan Kredensial**:
   - Berkas `.env` wajib masuk ke `.gitignore`. Dilarang melakukan commit API keys, private tokens, atau passwords ke version control.
   - Sediakan `.env.example` sebagai referensi struktur variabel yang bersih.
3. **Endpoint Whitelisting & Reverse Proxy**:
   - Di VPS, port `20128` hanya boleh diakses melalui reverse proxy Caddy internal atau loopback lokal, tidak diekspos ke public internet IP secara langsung.

---

## 5. Alur Kerja Siklus Hidup (Lifecycle Workflow)

1. **Understand & Plan**:
   - Periksa status terkini di `TODO.md`.
   - Pastikan tahap lokal berhasil dan diverifikasi sebelum merencanakan tahap VPS.
2. **Execute Cleanly**:
   - Konfigurasi file compose dan environment secara terstruktur.
3. **Verify Rigorously**:
   - Uji respons HTTP `GET /dashboard` atau endpoint `/v1/models`.
   - Uji pengiriman prompt via `/v1/chat/completions` menggunakan curl/skrip.
   - Pastikan fitur RTK Token Saver teruji kompresinya.
4. **Update TODO & Living Docs**:
   - Segera perbarui checkbox, status, dan catatan di `TODO.md`.
   - Tawarkan dokumentasi solusi ke Obsidian Second Brain (`D:\Apps\Obsidian\SecondBrain\02 Antigravity Core\Solution Library.md`).
