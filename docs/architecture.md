# System Architecture — 9Router AI Gateway

> **Status**: Approved & Baseline  
> **Target Audience**: AI Agents, System Engineers, Infrastructure Ops  
> **Last Updated**: 2026-09-16  

---

## 1. Arsitektur 3 Lapis (3-Layer Architecture)

Proyek ini menerapkan pemisahan tanggung jawab yang kaku demi determinisme, reliabilitas, dan kemudahan pelacakan (*traceability*):

```text
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Directive (Apa yang harus dicapai)                     │
│ • TODO.md (Master Checklist & Status Pelacakan)                 │
│ • docs/ (PRD.md, architecture.md)                               │
│ • directives/ (SOP Markdown: local-setup, vps-deployment, dll.) │
└────────────────────────────────┬────────────────────────────────┘
                                 │
┌────────────────────────────────▼────────────────────────────────┐
│ Layer 2: Orchestration (Pengambilan Keputusan & Koordinasi)     │
│ • Agen AI (Antigravity, Cursor, Claude Code)                    │
│ • Menilai konteks, memilih direktif, memvalidasi tahapan       │
│ • Mematuhi aturan operasional di AGENTS.md                      │
└────────────────────────────────┬────────────────────────────────┘
                                 │
┌────────────────────────────────▼────────────────────────────────┐
│ Layer 3: Execution (Eksekusi Deterministik & Tooling)           │
│ • execution/ (init-env.ps1, test-connection.ps1)                │
│ • Docker Compose (docker-compose.yml, docker-compose.vps.yml)   │
│ • CI/CD (.github/workflows/deploy.yml)                          │
│ • Reverse Proxy (Caddy proxy-network, tls internal)             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Topologi Jaringan & Komponen Sistem

### 2.1 Lingkungan Lokal (Windows Workstation)
- **Host**: Windows 11 x64 (Intel Core i7-13700HX, RTX 4050 6GB).
- **Runtime**: Docker Desktop (WSL2 backend).
- **Port Mapping**: Host `20128:20128` (Web UI Dashboard + API `/v1`).
- **Data Persistence**:
  - `./data:/app/data` (Menyimpan SQLite DB, kredensial pengguna, registrasi provider).
  - `./data/.9router:/root/.9router` (Menyimpan telemetri token, log penghematan RTK, dan cache).
- **Klien**:
  - Claude Code CLI (`http://localhost:20128/v1`).
  - Cursor / Cline (`http://localhost:20128/v1`).
  - Antigravity / skrip otomatisasi.

### 2.2 Lingkungan Produksi (Oracle Cloud VPS)
- **Host**: `vps-main` (IP Publik: `129.225.1.91`, SSH user: `ubuntu`, Ed25519 auth).
- **Arsitektur CPU**: ARM64 (`VM.Standard.A1.Flex`, 2 OCPU Ampere, 12 GB RAM).
- **Docker Image**: Multi-platform `linux/arm64` (`decolua/9router:latest`).
- **Jaringan**: Docker bridge eksternal `proxy-network`.
- **Port Binding**: Port `20128` **hanya** di-expose ke internal `proxy-network` (tidak di-publish ke `0.0.0.0`).
- **Reverse Proxy**: Caddy container (`caddy-proxy`).
  - Domain publik: `router.digitalneeds.my.id`.
  - DNS: Cloudflare Anycast (Proxied / Orange Cloud).
  - Konfigurasi Caddyfile:
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
  - **Bypass Cloudflare Error 525**: Direktif `tls internal` wajib disertakan agar Caddy menerbitkan sertifikat TLS lokal yang valid untuk handshake Cloudflare Full SSL mode.

---

## 3. Dual-Volume Persistence

9Router memiliki arsitektur penyimpanan dua direktori:
1. `/app/data`: Berisi database SQLite relasional yang menyimpan akun pengguna, konfigurasi model, provider keys, dan routing rules.
2. `/root/.9router`: Berisi file runtime telemetri, counter token, dan history kompresi RTK.

Kedua volume ini wajib dimount secara persisten. Jika salah satu tidak dimount, data telemetri atau konfigurasi akan terhapus ketika container di-restart atau di-pull image baru.

---

## 4. Invariant Lingkungan & Aturan Eksekusi

### 4.1 Windows PowerShell
- **Operator Pemisah**: Jangan pernah gunakan `&&` (menyebabkan syntax parse error di PowerShell). Gunakan titik koma `;` atau eksekusi baris terpisah.
- **Path Navigasi**: Hindari `cd` telanjang; gunakan path absolut atau path relatif terdefinisi.
- **Encoding Berkas**: Berkas konfigurasi (khususnya `.env`) yang dibaca container Linux wajib berformat **UTF-8 No BOM** dengan line ending bersih. Skrip `execution/init-env.ps1` dibuat khusus untuk menjamin encoding ini.

### 4.2 Git sebagai Single Source of Truth
- **Dilarang Live-Edit di VPS**: Segala perubahan konfigurasi docker-compose atau environment harus diuji secara lokal, di-commit ke repositori Git, dan dideploy via CI/CD.
- **Proteksi Secret**: Berkas `.env`, data database, dan kunci SSH tidak boleh masuk ke commit Git.

---

## 5. Architectural Decision Log (ADR)

| ID | Tanggal | Topik | Keputusan | Rasional |
| :--- | :--- | :--- | :--- | :--- |
| **DEC-01** | 2026-09-16 | Arsitektur Deployment | Local-First kemudian VPS | Menghindari risiko konfigurasi rusak di server produksi; seluruh alur divalidasi lokal terlebih dahulu. |
| **DEC-02** | 2026-09-16 | Port & Network VPS | Port 20128 internal via `proxy-network` | Mencegah port 20128 terbuka langsung ke internet publik; seluruh lalu lintas HTTPS dialihkan melalui Caddy & Cloudflare. |
| **DEC-03** | 2026-09-16 | Keamanan Image | Mitigasi CVE-2026-46339 | Gunakan image resmi teranyar, isolasi container, dan wajibkan `REQUIRE_API_KEY=true` di server VPS. |
| **DEC-04** | 2026-09-16 | Git Source of Truth | Deployment via CI/CD | Menegakkan prinsip tidak mengubah kode/compose langsung di VPS; semua perubahan diuji lokal dan di-push ke GitHub. |
| **DEC-05** | 2026-09-16 | Data Persistence | Dual-Volume (`/app/data` + `/root/.9router`) | 9Router memisahkan database config dan telemetri; keduanya harus dipetakan agar data aman saat restart. |
| **DEC-06** | 2026-09-16 | Caddy TLS Invariant | Wajib `tls internal` | Mencegah Cloudflare Error 525 (SSL Handshake Failed) saat Cloudflare Proxy dalam mode Full. |
| **DEC-07** | 2026-09-16 | Skrip Otomasi & Encoding | PowerShell UTF-8 No BOM | Mencegah kerusakan encoding karakter (UTF-8 BOM dan CRLF) saat membaca `.env` di Linux container. |
