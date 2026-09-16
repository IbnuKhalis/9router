# 9Router Implementation Roadmap & Master Checklist

> **Proyek**: 9Router AI Model Gateway & Token Optimizer  
> **Jalur Eksekusi**: **Lokal (Windows Docker)** ➔ **VPS Produksi (Oracle Cloud ARM64 + Caddy)**  
> **Status Master**: `FASE 0: INISIASI & BASELINE` 🟢 | `FASE 1: SETUP LOKAL` 🟡  
> **Terakhir Diperbarui**: 2026-09-16

---

## 🧭 Ringkasan Arsitektur & Tujuan

9Router diimplementasikan sebagai **AI Model Routing Layer terpusat** dengan kemampuan:
1. **Universal Endpoint**: Menyediakan endpoint kompatibel OpenAI (`/v1`) untuk seluruh AI coding tools (Antigravity, Claude Code, Cursor, Cline, script Python).
2. **RTK Token Saver & Headroom**: Mengompresi input context & tool output (git diff, grep, logs) untuk menghemat 20% - 40% token input, dengan opsi Headroom sidecar untuk kompresi context lanjutan.
3. **Smart Auto-Fallback**: Otomatis mengalihkan request ke model murah/gratis (Kiro AI, OpenCode Free, Gemini/Vertex) saat model utama mencapai rate limit atau kuota habis.
4. **Strategi Deployment Berjenjang**:
   - **Tahap 1 (Lokal)**: Berjalan di Windows Docker Desktop (`http://localhost:20128`), fokus pada eksplorasi, konfigurasi provider, uji coba RTK, dan integrasi CLI.
   - **Tahap 2 (VPS Produksi)**: Berjalan di server Oracle Cloud ARM64 (`vps-main`, `129.225.1.91`) dengan reverse proxy Caddy (`https://router.digitalneeds.my.id`), SSL Cloudflare, dan Docker network `proxy-network`.

---

## 📊 Matriks Progres Proyek

| Fase | Deskripsi | Lingkungan | Status |
| :--- | :--- | :--- | :---: |
| **Fase 0** | Inisiasi Repositori & Panduan Operasional | Lokal | 🟢 SELESAI |
| **Fase 1** | Konfigurasi & Setup Docker Lokal | Lokal Windows | 🟡 SIAP DIEKSEKUSI |
| **Fase 2** | Akses Dashboard & Registrasi Provider Model | Lokal Windows | ⚪ MENUNGGU |
| **Fase 3** | Uji Coba RTK Token Saver & Smart Fallback | Lokal Windows | ⚪ MENUNGGU |
| **Fase 4** | Integrasi Tool Koding Workstation (Cursor/Claude/Antigravity) | Lokal Windows | ⚪ MENUNGGU |
| **Fase 5** | Persiapan & Hardening Deployment VPS (ARM64) | VPS Persiapan | ⚪ MENUNGGU |
| **Fase 6** | Deployment VPS & Konfigurasi Caddy SSL | VPS Produksi | ⚪ MENUNGGU |
| **Fase 7** | Integrasi Lintas Proyek & Sinkronisasi Second Brain | Ekosistem | ⚪ MENUNGGU |

---

## 📋 Rincian Langkah & Checklist

### 🟢 Fase 0: Inisiasi Repositori & Baseline Lingkungan (Sesuai Agent Instructions.md)
- [x] Siapkan operating rules agen [`Agent Instructions.md`](file:///d:/Antigravity/9router/Agent%20Instructions.md) & cermin multi-agent ([`AGENTS.md`](file:///d:/Antigravity/9router/AGENTS.md), [`CLAUDE.md`](file:///d:/Antigravity/9router/CLAUDE.md), [`GEMINI.md`](file:///d:/Antigravity/9router/GEMINI.md))
- [x] Buat konteks proyek `docs/`: Product Requirements Document [`docs/PRD.md`](file:///d:/Antigravity/9router/docs/PRD.md) & System Architecture [`docs/architecture.md`](file:///d:/Antigravity/9router/docs/architecture.md)
- [x] Buat prosedur SOP `directives/`:
  - [x] Local Setup SOP [`directives/local-setup.md`](file:///d:/Antigravity/9router/directives/local-setup.md)
  - [x] Production VPS Deployment SOP [`directives/vps-deployment.md`](file:///d:/Antigravity/9router/directives/vps-deployment.md)
  - [x] Connection & API Diagnostics SOP [`directives/connection-test.md`](file:///d:/Antigravity/9router/directives/connection-test.md)
  - [x] GitHub Push & Version Control SOP [`directives/github-push.md`](file:///d:/Antigravity/9router/directives/github-push.md)
- [x] Buat master roadmap [`TODO.md`](file:///d:/Antigravity/9router/TODO.md)
- [x] Inisialisasi Git repositori lokal (`git init`)
- [x] Buat berkas [`.gitignore`](file:///d:/Antigravity/9router/.gitignore) (abaikan `.env`, data volume, log)
- [x] Buat berkas template konfigurasi [`.env.example`](file:///d:/Antigravity/9router/.env.example)
- [x] Buat berkas konfigurasi [`docker-compose.yml`](file:///d:/Antigravity/9router/docker-compose.yml) (Lokal Windows, dual volume `/app/data` + `/root/.9router`)
- [x] Buat berkas konfigurasi [`docker-compose.vps.yml`](file:///d:/Antigravity/9router/docker-compose.vps.yml) (VPS Oracle Cloud ARM64)
- [x] Buat skrip eksekusi deterministik `execution/`:
  - [x] Inisialisasi lingkungan [`execution/init-env.ps1`](file:///d:/Antigravity/9router/execution/init-env.ps1) (Aman UTF-8 No BOM)
  - [x] Diagnostik endpoint [`execution/test-connection.ps1`](file:///d:/Antigravity/9router/execution/test-connection.ps1)
- [x] Buat alur kerja CI/CD GitHub Actions [`.github/workflows/deploy.yml`](file:///d:/Antigravity/9router/.github/workflows/deploy.yml)

---

### 🟡 Fase 1: Setup & Konfigurasi Docker Lokal (Windows)
> **Tujuan**: Menjalankan 9Router secara stabil di Windows menggunakan Docker Desktop sebelum menyentuh VPS.

- [ ] Pastikan Docker Desktop di Windows berjalan:
  ```powershell
  Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
  # Tunggu engine siap, lalu cek:
  docker info
  ```
- [ ] Inisialisasi berkas konfigurasi `.env` dan direktori data persisten (lihat [`directives/local-setup.md`](file:///d:/Antigravity/9router/directives/local-setup.md)):
  ```powershell
  .\execution\init-env.ps1
  ```
  *Skrip ini otomatis menghasilkan JWT_SECRET acak, password login dashboard yang aman, serta membuat folder `data/` dan `data/.9router/`.*
- [ ] Jalankan container 9Router lokal:
  ```powershell
  docker compose up -d
  ```
- [ ] Periksa log container untuk memastikan database SQLite dan service aktif:
  ```powershell
  docker compose logs -f 9router
  ```
- [ ] Verifikasi diagnostik otomatis:
  ```powershell
  .\execution\test-connection.ps1
  ```

---

### ⚪ Fase 2: Akses Dashboard & Registrasi Provider Model AI
> **Tujuan**: Membuka dashboard 9Router dan menghubungkan model-model AI gratis/berbayar.

- [ ] Akses Web UI Dashboard via browser: `http://localhost:20128`
- [ ] Login menggunakan kredensial yang dihasilkan oleh `init-env.ps1` (atau password default `123456` jika `INITIAL_PASSWORD` tidak diset).
- [ ] Daftarkan Provider Model Gratis (Zero Cost AI Coding):
  - [ ] **Kiro AI**: Claude 4.5, GLM-5, MiniMax (kuota gratis bulanan)
  - [ ] **OpenCode Free**: Model gratis terotomasi tanpa autentikasi
  - [ ] **Google Vertex AI / Gemini Studio**: Masukkan API key Gemini gratis
- [ ] Daftarkan Provider Berbayar / Langganan (Opsional):
  - [ ] Anthropic Claude API Key / Claude Code OAuth
  - [ ] OpenAI API Key
  - [ ] DeepSeek API Key
  - [ ] OpenRouter API Key
- [ ] Buat Master API Key di menu **API Keys** Dashboard 9Router dan simpan untuk pengujian CLI.

---

### ⚪ Fase 3: Uji Coba RTK Token Saver & Smart Fallback
> **Tujuan**: Membuktikan bahwa 9Router dapat memproses request LLM dan menghemat token.

- [ ] Uji diagnostik koneksi model terdaftar (lihat [`directives/connection-test.md`](file:///d:/Antigravity/9router/directives/connection-test.md)):
  ```powershell
  .\execution\test-connection.ps1 -ApiKey "<MASTER_API_KEY>"
  ```
- [ ] Uji pengiriman prompt chat completion:
  ```powershell
  .\execution\test-connection.ps1 -ApiKey "<MASTER_API_KEY>" -Model "auto" -SendChatPrompt
  ```
- [ ] Uji efektivitas **RTK Token Saver**:
  - Kirimkan context berukuran besar (misal git diff panjang atau output file).
  - Amati persentase kompresi token yang tercatat pada dashboard 9Router (ekspektasi 20% - 40% penghematan).
- [ ] Uji **Smart Auto-Fallback**:
  - Simulasikan provider utama mati / rate limited.
  - Pastikan 9Router otomatis mengalihkan request ke provider tier kedua tanpa error koneksi pada klien.

---

### ⚪ Fase 4: Integrasi Tool Koding Workstation
> **Tujuan**: Menjadikan 9Router sebagai gateway default untuk alat pengembangan di PC pengguna.

- [ ] Konfigurasi pada **Claude Code CLI**:
  - Base URL: `http://localhost:20128/v1`
  - Auth token: `[9Router Master API Key]`
- [ ] Konfigurasi pada **Cursor / Cline / Roo Code / OpenClaw**:
  - OpenAI API Base: `http://localhost:20128/v1`
  - API Key: `[9Router Master API Key]`
  - Model: Model alias dari 9Router (misal `kr/claude-sonnet-4.5` atau `auto`)
- [ ] Uji coding live di editor dan verifikasi token savings di dashboard.

---

### ⚪ Fase 5: Persiapan & Hardening Deployment VPS (ARM64)
> **Tujuan**: Menyiapkan konfigurasi server produksi yang aman sebelum melakukan deployment ke Oracle Cloud.

- [ ] Verifikasi kompatibilitas image ARM64:
  - `decolua/9router:latest` mendukung platform `linux/arm64` secara native.
- [ ] Konfigurasi Docker Compose VPS [`docker-compose.vps.yml`](file:///d:/Antigravity/9router/docker-compose.vps.yml):
  - Terhubung ke Docker bridge eksternal: `proxy-network`
  - Tanpa port mapping publik mentah (`expose: - "20128"` saja).
  - Dual volume persisten: `9router_vps_data:/app/data` dan `9router_vps_root:/root/.9router`.
- [ ] Konfigurasi DNS Cloudflare:
  - DNS Wildcard `*.digitalneeds.my.id` sudah aktif mengarah ke `129.225.1.91` (Proxied).
- [ ] Tambahkan blok Caddyfile di VPS (`/opt/infrastructure/reverse-proxy/Caddyfile`):
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
- [ ] Terapkan mitigasi keamanan CVE-2026-46339:
  - Atur `REQUIRE_API_KEY=true` di lingkungan produksi VPS.
  - Port `20128` terisolasi di dalam `proxy-network`.

---

### ⚪ Fase 6: Eksekusi Deployment ke VPS & Verifikasi Remote
> **Tujuan**: Melakukan deployment otomatis ke VPS melalui alur CI/CD GitHub Actions (Git as Single Source of Truth).

- [ ] Buat repositori GitHub pribadi `IbnuKhalis/9router` via GitHub CLI:
  ```powershell
  gh repo create IbnuKhalis/9router --private --source=. --remote=origin
  ```
- [ ] Daftarkan 4 secret deployment VPS menggunakan fungsi PowerShell bawaan:
  ```powershell
  set-vps-secrets 9router
  ```
- [ ] Push kode ke branch `main`:
  ```powershell
  git push -u origin main
  ```
- [ ] Pantau pipeline GitHub Actions di [`.github/workflows/deploy.yml`](file:///d:/Antigravity/9router/.github/workflows/deploy.yml) hingga selesai.
- [ ] Verifikasi reload konfigurasi Caddy di VPS:
  ```powershell
  ssh vps-main "docker exec caddy-proxy caddy reload --config /etc/caddy/Caddyfile"
  ```
- [ ] Uji endpoint publik HTTPS (lihat [`directives/vps-deployment.md`](file:///d:/Antigravity/9router/directives/vps-deployment.md)):
  - Buka browser: `https://router.digitalneeds.my.id`
  - Uji cURL HTTPS:
    ```powershell
    .\execution\test-connection.ps1 -BaseUrl "https://router.digitalneeds.my.id" -ApiKey "<VPS_API_KEY>"
    ```

---

### ⚪ Fase 7: Integrasi Lintas Proyek & Dokumentasi Second Brain
> **Tujuan**: Memanfaatkan 9Router untuk proyek lain dan mengabadikan pengetahuan ke Obsidian Second Brain.

- [ ] Integrasikan 9Router VPS sebagai gateway model bagi:
  - **VPS-Monitor-Dashboard**: Ringkasan status server berkala menggunakan model AI hemat token.
  - **Graduance**: Bantuan analisis data atau fitur AI portal.
  - **Second Brain AI Gateway**: Menghubungkan router model untuk semantic search / summary notes.
- [ ] Dokumentasi ke Obsidian Second Brain:
  - [ ] Buat ringkasan arsitektur di `D:\Apps\Obsidian\SecondBrain\01 Projects\Antigravity\9router\Overview.md`
  - [ ] Tambahkan tips setup dan solusi routing ke `02 Antigravity Core\Solution Library.md`
  - [ ] Catat milestone ke jurnal harian `00 Daily/<YYYY-MM-DD>.md`

---

## 🔒 Decision Log & Catatan Teknis

| ID | Tanggal | Topik | Keputusan | Rasional |
| :--- | :--- | :--- | :--- | :--- |
| **DEC-01** | 2026-09-16 | Arsitektur Deployment | Local-First kemudian VPS | Memastikan konfigurasi provider, API token, dan fitur RTK terbukti berhasil secara lokal sebelum diekspos ke VPS cloud. |
| **DEC-02** | 2026-09-16 | Port & Network VPS | Port 20128 internal via `proxy-network` | Mencegah port 20128 terbuka langsung ke internet publik; seluruh lalu lintas HTTPS dialihkan melalui Caddy & Cloudflare Anycast. |
| **DEC-03** | 2026-09-16 | Keamanan Image | Mitigasi CVE-2026-46339 | Gunakan image resmi teranyar, isolasi container, dan wajibkan `REQUIRE_API_KEY=true` di server VPS. |
| **DEC-04** | 2026-09-16 | Git Source of Truth | Deployment via CI/CD | Menegakkan prinsip tidak mengubah kode/compose langsung di VPS; semua perubahan diuji lokal dan di-push ke GitHub. |
| **DEC-05** | 2026-09-16 | Data Persistence | Dual-Volume (`/app/data` + `/root/.9router`) | 9Router menyimpan konfigurasi SQLite di `/app/data`, namun telemetri token dan request logs disimpan di `/root/.9router`. Kedua volume wajib dipetakan agar tidak terjadi kehilangan data saat container di-restart. |
| **DEC-06** | 2026-09-16 | Caddy TLS Invariant | Wajib `tls internal` | Mencegah Cloudflare Error 525 (SSL Handshake Failed) saat Cloudflare Proxy dalam mode Full; origin TLS diterbitkan instan oleh internal CA Caddy. |
| **DEC-07** | 2026-09-16 | Skrip Otomasi & Encoding | PowerShell UTF-8 No BOM | Mencegah kerusakan encoding karakter (UTF-8 BOM dan CRLF) saat membaca `.env` di Linux container; diotomasi melalui `execution/init-env.ps1`. |

