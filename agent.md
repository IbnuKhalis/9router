# Agent Instructions — 9Router AI Gateway

> Berkas ini mendefinisikan standar operasional, arsitektur, dan batasan keamanan untuk agen AI dalam proyek **9Router**.
> Berkas ini dirujuk dan diselaraskan di [`AGENTS.md`](file:///d:/Antigravity/9router/AGENTS.md) agar seluruh ekosistem AI coding (Antigravity, Claude Code, Cursor, Cline) mematuhi invariant yang sama.

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
│ • Skrip otomatisasi (scripts/init-env.ps1, test-connection.ps1) │
│ • CI/CD (.github/workflows/deploy.yml)                  │
│ • Reverse proxy (Caddy: tls internal di caddy-proxy)    │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Peran & Batasan 9Router dalam Ekosistem Pengguna

1. **Routing Layer, Bukan Pengganti Agen**:
   - 9Router bertindak murni sebagai **API Gateway & Model Router** (OpenAI-compatible endpoint `http://localhost:20128/v1` atau reverse proxy VPS `https://router.digitalneeds.my.id/v1`).
   - Agen koding utama tetap **Antigravity** (serta tool CLI seperti Claude Code / Cursor). 9Router menyediakan endpoint LLM dengan token saver (RTK / Headroom) dan smart auto-fallback.
2. **Kemandirian Workspace**:
   - 9Router mengelola routing model dan API credentials; direktori proyek aplikasi lain (seperti `graduance`, `VPS-Monitor-Dashboard`, `Second-Brain`) tetap independen.

---

## 3. Invariant Lingkungan (Environment Invariants)

### 3.1 Workstation Lokal (Windows)
- **Sistem Operasi**: Windows 11 x64, CPU Intel i7-13700HX, GPU RTX 4050 6GB.
- **Terminal Shell**: PowerShell.
- **Aturan Sintaks PowerShell & Encoding**:
  - Dilarang menggunakan operator `&&` (memicu `ParserError`). Gunakan titik koma `;` atau jalankan perintah secara terpisah.
  - Jangan gunakan perintah `cd` tersendiri; selalu tentukan path kerja secara eksplisit.
  - **UTF-8 No BOM**: Berkas teks (khususnya `.env`) yang dibaca container Linux **wajib UTF-8 tanpa BOM** dan line-ending LF/CRLF bersih. Gunakan `.\scripts\init-env.ps1` untuk inisialisasi yang aman.
- **Docker Desktop**:
  - Container dijalankan via Docker Compose (`decolua/9router:latest`).
  - Port default: `20128`. Dashboard web: `http://localhost:20128`.
  - **Dual-Volume Persistence**: 9Router menyimpan konfigurasi database di `/app/data` dan log telemetri/token di `/root/.9router`. Keduanya wajib dipetakan (`./data:/app/data` dan `./data/.9router:/root/.9router`) agar data tidak hilang saat container restart.

### 3.2 Server Produksi (Oracle Cloud VPS)
- **Host Alias**: `vps-main` (IP: `129.225.1.91`, SSH user: `ubuntu`, key Ed25519 `~/.ssh/id_oracle_vps`).
- **Arsitektur CPU**: ARM64 (`VM.Standard.A1.Flex`, 2 OCPU Ampere, 12 GB RAM). Image Docker `decolua/9router` telah mendukung multi-platform `linux/arm64`.
- **Aturan Git sebagai Single Source of Truth**:
  - **Dilarang keras melakukan live-edit langsung di server VPS**. Semua perubahan konfigurasi dan berkas docker compose harus diuji secara lokal, di-commit, dan di-push ke GitHub.
  - Deployment ke VPS dijalankan melalui alur CI/CD GitHub Actions (`.github/workflows/deploy.yml`) atau skrip deterministik.
- **Jaringan & Reverse Proxy Caddy**:
  - Bergabung ke Docker bridge eksternal: `proxy-network`.
  - Nama container reverse proxy di server adalah **`caddy-proxy`**. Perintah reload:
    ```bash
    docker exec caddy-proxy caddy reload --config /etc/caddy/Caddyfile
    ```
  - **Bypass Cloudflare Error 525**: Blok domain pada `/opt/infrastructure/reverse-proxy/Caddyfile` **wajib** menyertakan direktif `tls internal` dan security headers:
    ```caddyfile
    router.digitalneeds.my.id {
        tls internal
        reverse_proxy 9router:20128
        encode gzip zstd

        header {
            Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
            X-Content-Type-Options "nosniff"
            X-Frame-Options "SAMEORIGIN"
            Referrer-Policy "strict-origin-when-cross-origin"
        }
    }
    ```
  - Port `20128` hanya di-expose ke `proxy-network`, tidak pernah di-publish langsung ke port host publik.

---

## 4. Standar Keamanan & Mitigasi Kerentanan

1. **Mitigasi CVE-2026-46339 & Autentikasi**:
   - Pastikan menggunakan image 9Router versi teranyar yang sudah menambal celah RCE unauthenticated.
   - Wajib mengatur `JWT_SECRET` (string acak minimal 32 karakter) dan `INITIAL_PASSWORD` yang kuat.
   - Di VPS publik, wajib setel `REQUIRE_API_KEY=true` agar endpoint `/v1/*` tidak terbuka untuk umum.
2. **Perlindungan Kredensial**:
   - Berkas `.env` wajib masuk ke `.gitignore`. Dilarang melakukan commit API keys, private tokens, atau passwords ke version control.
   - Sediakan `.env.example` sebagai referensi struktur variabel yang bersih.

---

## 5. Alur Kerja Siklus Hidup & Tooling

1. **Inisialisasi Lingkungan**:
   - Jalankan `.\scripts\init-env.ps1` untuk membuat `.env` dan folder data secara otomatis dan aman.
2. **Eksekusi Lokal**:
   - Start Docker Desktop di Windows.
   - Jalankan container dengan `docker compose up -d`.
3. **Verifikasi Deterministik**:
   - Jalankan `.\scripts\test-connection.ps1` untuk memeriksa kesiapan HTTP dashboard dan endpoint `/v1/models`.
   - Gunakan `.\scripts\test-connection.ps1 -SendChatPrompt` setelah provider model terhubung.
4. **Update TODO & Living Docs**:
   - Segera perbarui checkbox, status, dan catatan di [`TODO.md`](file:///d:/Antigravity/9router/TODO.md).
   - Tawarkan dokumentasi arsitektur ke Obsidian Second Brain (`D:\Apps\Obsidian\SecondBrain\02 Antigravity Core\Solution Library.md`).

