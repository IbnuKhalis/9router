# 9Router Implementation Roadmap & Master Checklist

> **Proyek**: 9Router AI Model Gateway & Token Optimizer  
> **Jalur Eksekusi**: **Lokal (Windows Docker)** ➔ **VPS Produksi (Oracle Cloud ARM64 + Caddy)**  
> **Status Master**: `FASE 0: INISIASI & BASELINE` 🟡  
> **Terakhir Diperbarui**: 2026-09-16

---

## 🧭 Ringkasan Arsitektur & Tujuan

9Router diimplementasikan sebagai **AI Model Routing Layer terpusat** dengan kemampuan:
1. **Universal Endpoint**: Menyediakan endpoint kompatibel OpenAI (`/v1`) untuk seluruh AI coding tools (Antigravity, Claude Code, Cursor, Cline, script Python).
2. **RTK Token Saver**: Mengompresi input context & tool output (git diff, grep, logs) untuk menghemat 20% - 40% token input.
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

### 🟢 Fase 0: Inisiasi Repositori & Baseline Lingkungan
- [x] Buat berkas panduan operasional agen [`agent.md`](file:///d:/Antigravity/9router/agent.md)
- [x] Buat cermin [`AGENTS.md`](file:///d:/Antigravity/9router/AGENTS.md) untuk kompatibilitas multi-agent
- [x] Buat master roadmap [`TODO.md`](file:///d:/Antigravity/9router/TODO.md)
- [x] Inisialisasi Git repositori lokal (`git init`)
- [x] Buat berkas [`.gitignore`](file:///d:/Antigravity/9router/.gitignore) (abaikan `.env`, data volume, log)
- [x] Buat berkas template konfigurasi [`.env.example`](file:///d:/Antigravity/9router/.env.example)
- [x] Buat berkas konfigurasi [`docker-compose.yml`](file:///d:/Antigravity/9router/docker-compose.yml) (Lokal Windows)
- [x] Buat berkas konfigurasi [`docker-compose.vps.yml`](file:///d:/Antigravity/9router/docker-compose.vps.yml) (VPS Oracle Cloud ARM64)

---

### 🟡 Fase 1: Setup & Konfigurasi Docker Lokal (Windows)
> **Tujuan**: Menjalankan 9Router secara stabil di Windows menggunakan Docker Desktop sebelum menyentuh VPS.

- [ ] Pastikan Docker Desktop di Windows berjalan (`docker info`)
- [ ] Buat berkas [`docker-compose.yml`](file:///d:/Antigravity/9router/docker-compose.yml) untuk lingkungan lokal:
  - Image: `decolua/9router:latest`
  - Container name: `9router`
  - Port mapping: `20128:20128`
  - Volume data: `./data:/app/data` atau named volume `9router-data:/app/data`
  - Environment: `DATA_DIR=/app/data`, `PORT=20128`, `HOSTNAME=0.0.0.0`
- [ ] Buat berkas `.env` lokal dari `.env.example`:
  - Atur `JWT_SECRET` dengan string acak yang kuat
  - Atur `INITIAL_PASSWORD` untuk login pertama dashboard
  - Atur `REQUIRE_API_KEY=false` (atau `true` jika ingin langsung uji proteksi)
- [ ] Jalankan container lokal:
  ```powershell
  docker compose up -d
  ```
- [ ] Periksa log container untuk memastikan database SQLite terinisialisasi bersih:
  ```powershell
  docker compose logs -f 9router
  ```
- [ ] Verifikasi container status sehat (`docker ps | Select-String "9router"`)

---

### ⚪ Fase 2: Akses Dashboard & Registrasi Provider Model AI
> **Tujuan**: Membuka dashboard 9Router dan menghubungkan model-model AI gratis/berbayar.

- [ ] Akses Web UI Dashboard via browser: `http://localhost:20128/dashboard`
- [ ] Login menggunakan kredensial awal (`INITIAL_PASSWORD`)
- [ ] Daftarkan Provider Model Gratis (Tanpa Biaya Tambahan):
  - [ ] **Kiro AI**: Claude 4.5, GLM-5, MiniMax (kuota bulanan gratis)
  - [ ] **OpenCode Free**: Model gratis terotomasi tanpa autentikasi
  - [ ] **Google Vertex AI / Gemini API**: Jika memiliki kuota Gemini Studio / Cloud credits
- [ ] Daftarkan Provider Berbayar / Langganan (Opsional/Sesuai Akun Pengguna):
  - [ ] Anthropic Claude API Key / Claude Code OAuth
  - [ ] OpenAI API Key
  - [ ] DeepSeek API Key
  - [ ] OpenRouter API Key
- [ ] Salin 9Router Master API Key yang dihasilkan di Dashboard untuk pengujian API.

---

### ⚪ Fase 3: Uji Coba RTK Token Saver & Smart Fallback
> **Tujuan**: Membuktikan bahwa 9Router dapat memproses request LLM dan menghemat token.

- [ ] Uji endpoint model list:
  ```powershell
  curl.exe -s http://localhost:20128/v1/models -H "Authorization: Bearer <API_KEY>"
  ```
- [ ] Uji basic chat completion:
  ```powershell
  curl.exe -s http://localhost:20128/v1/chat/completions `
    -H "Content-Type: application/json" `
    -H "Authorization: Bearer <API_KEY>" `
    -d '{"model": "auto", "messages": [{"role": "user", "content": "Halo 9Router, tes koneksi!"}]}'
  ```
- [ ] Uji efektivitas **RTK Token Saver**:
  - Kirimkan context berukuran besar (misal git diff panjang atau output log).
  - Amati persentase kompresi token yang tercatat pada dashboard 9Router (ekspektasi 20% - 40% penghematan).
- [ ] Uji **Smart Auto-Fallback**:
  - Simulasikan limit atau provider mati pada tier pertama.
  - Verifikasi request otomatis dialihkan ke provider tier berikutnya tanpa error koneksi pada klien.

---

### ⚪ Fase 4: Integrasi Tool Koding Workstation
> **Tujuan**: Menjadikan 9Router sebagai gateway default untuk alat pengembangan di PC pengguna.

- [ ] Konfigurasi pada **Claude Code CLI**:
  - Set base URL ke `http://localhost:20128/v1`
  - Set token autentikasi 9Router
- [ ] Konfigurasi pada **Cursor / Cline / Roo Code / OpenClaw**:
  - OpenAI-compatible API base: `http://localhost:20128/v1`
  - API Key: `[9Router API Key]`
  - Model: Model alias dari 9Router (misal `kr/claude-sonnet-4.5` atau `auto`)
- [ ] Uji interaksi coding live dari editor menggunakan model hasil routing 9Router.

---

### ⚪ Fase 5: Persiapan & Hardening Deployment VPS (ARM64)
> **Tujuan**: Menyiapkan konfigurasi server produksi yang aman sebelum melakukan deployment ke Oracle Cloud.

- [ ] Verifikasi kompatibilitas image ARM64:
  - `decolua/9router:latest` mendukung platform `linux/arm64` secara native (kompatibel dengan Ampere A1 di `vps-main`).
- [ ] Buat berkas konfigurasi VPS [`docker-compose.vps.yml`](file:///d:/Antigravity/9router/docker-compose.vps.yml):
  - Terhubung ke Docker bridge eksternal: `proxy-network`
  - Tanpa port mapping publik mentah (`expose: - "20128"` saja, bukan `ports: - "20128:20128"`) agar aman dari perimeter luar.
  - Volume data persisten di server host: `/opt/projects/9router/data:/app/data`
- [ ] Siapkan konfigurasi DNS Cloudflare:
  - Buat DNS record A: `router.digitalneeds.my.id` ➔ `129.225.1.91` (Proxy Status: Proxied, SSL Full).
- [ ] Siapkan blok Caddyfile untuk reverse proxy di `/opt/infrastructure/reverse-proxy/Caddyfile`:
  ```caddy
  router.digitalneeds.my.id {
      reverse_proxy 9router:20128
  }
  ```
- [ ] Terapkan checklist keamanan (Mitigasi CVE-2026-46339):
  - Atur `REQUIRE_API_KEY=true` di environment produksi VPS.
  - Pastikan port `20128` diblokir oleh UFW host dan tidak dibuka di OCI Security List.
  - Kredensial dashboard menggunakan password acak dengan entropi tinggi.

---

### ⚪ Fase 6: Eksekusi Deployment ke VPS & Verifikasi Remote
> **Tujuan**: Melakukan deployment otomatis ke VPS melalui alur CI/CD GitHub Actions (Git as Single Source of Truth).

- [ ] Buat repositori GitHub pribadi `IbnuKhalis/9router` via GitHub CLI (`gh repo create`).
- [ ] Daftarkan secret CI/CD ke repositori (`VPS_HOST`, `VPS_USERNAME`, `VPS_PORT`, `VPS_SSH_KEY`) via helper PowerShell `set-vps-secrets`.
- [ ] Buat alur kerja GitHub Actions `.github/workflows/deploy.yml` untuk auto-deploy ke `/opt/projects/9router`.
- [ ] Commit dan push branch `main` ke GitHub.
- [ ] Verifikasi pipeline CI/CD di GitHub Actions berhasil dijalankan.
- [ ] Verifikasi reload konfigurasi Caddy di VPS:
  ```powershell
  ssh vps-main "cd /opt/infrastructure/reverse-proxy; docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile"
  ```
- [ ] Uji endpoint publik HTTPS:
  - Buka browser: `https://router.digitalneeds.my.id/dashboard`
  - Uji cURL HTTPS:
    ```powershell
    curl.exe -s https://router.digitalneeds.my.id/v1/models -H "Authorization: Bearer <VPS_API_KEY>"
    ```

---

### ⚪ Fase 7: Integrasi Lintas Proyek & Dokumentasi Second Brain
> **Tujuan**: Memanfaatkan 9Router untuk proyek lain dan mengabadikan pengetahuan ke Obsidian Second Brain.

- [ ] Integrasikan 9Router VPS sebagai gateway fallback bagi:
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
