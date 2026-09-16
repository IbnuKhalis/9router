# Directive: Production VPS Deployment

## Goal
Melakukan deployment container 9Router ke server VPS Oracle Cloud ARM64 (`vps-main`, `129.225.1.91`) secara otomatis dan aman menggunakan GitHub Actions CI/CD, mengonfigurasi routing domain `router.digitalneeds.my.id` melalui Caddy reverse proxy, dan memverifikasi endpoint HTTPS publik.

---

## Required Inputs
- Akses SSH ke server VPS: `vps-main` (`129.225.1.91`, user `ubuntu`, key `~/.ssh/id_oracle_vps`).
- Repositori GitHub pribadi `IbnuKhalis/9router`.
- GitHub Actions Secrets terpasang:
  - `VPS_HOST`: `129.225.1.91`
  - `VPS_USERNAME`: `ubuntu`
  - `VPS_SSH_KEY`: Private key SSH Ed25519
  - `VPS_PORT`: `22`
- Docker network eksternal di VPS: `proxy-network`.
- Reverse proxy Caddy aktif di VPS (`caddy-proxy`).

---

## Tools & Execution Scripts
- GitHub Actions CI/CD: `.github/workflows/deploy.yml`.
- Docker Compose VPS: `docker-compose.vps.yml`.
- Skrip Diagnostik: `execution/test-connection.ps1`.
- Caddy CLI: `docker exec caddy-proxy caddy reload --config /etc/caddy/Caddyfile`.

---

## Step-by-Step Procedure

### 1. Verifikasi Kesiapan Lokal
Pastikan seluruh pengujian lokal di Fase 1 hingga Fase 4 telah berhasil sebelum menyentuh VPS:
- [ ] Container lokal berjalan stabil.
- [ ] Master API Key telah dibuat dan diuji.

### 2. Konfigurasi Blok Domain Caddy di VPS
Pastikan Caddyfile di server VPS (`/opt/infrastructure/reverse-proxy/Caddyfile`) memuat blok konfigurasi untuk 9Router dengan invariant `tls internal`:
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

Reload Caddy untuk menerapkan konfigurasi:
```bash
docker exec caddy-proxy caddy reload --config /etc/caddy/Caddyfile
```

### 3. Daftarkan GitHub Secrets & Push ke Main
Ikuti direktif `directives/github-push.md` untuk push kode:
```powershell
set-vps-secrets 9router
git push origin main
```

### 4. Pantau Pipeline GitHub Actions
- Buka tab Actions di repositori GitHub atau periksa status alur kerja `Deploy 9Router to VPS`.
- Alur kerja akan melakukan SSH ke VPS, clone/pull kode ke `/opt/projects/9router`, menjalankan `docker compose -f docker-compose.vps.yml up -d`, dan me-reload Caddy.

### 5. Verifikasi Endpoint Produksi
Uji endpoint publik HTTPS dari workstation lokal:
```powershell
.\execution\test-connection.ps1 -BaseUrl "https://router.digitalneeds.my.id" -ApiKey "<VPS_API_KEY>"
```

---

## Expected Outputs
- Container `9router` berjalan di VPS dalam jaringan `proxy-network`.
- Port 20128 tidak terpublikasi ke internet publik (hanya internal container).
- Akses web browser ke `https://router.digitalneeds.my.id` berhasil dengan sertifikat valid Cloudflare.
- Endpoint `/v1/models` merespons request terautentikasi.

---

## Important Constraints
- **Git as Single Source of Truth**: Dilarang mengedit berkas docker-compose langsung di server VPS.
- **Port Security**: Dilarang menambahkan port mapping `ports: - "20128:20128"` pada `docker-compose.vps.yml`.
- **Caddy Invariant**: Wajib menggunakan `tls internal` untuk menghindari Cloudflare Error 525.

---

## Known Edge Cases & Recovery
1. **Cloudflare Error 525 (SSL Handshake Failed)**:
   - Penyebab: Caddy mencoba mengurus sertifikat Let's Encrypt publik via HTTP challenge saat Cloudflare DNS proxied, atau TLS handshake origin gagal.
   - Solusi: Pastikan `tls internal` ada di blok domain Caddyfile VPS, lalu jalankan `docker exec caddy-proxy caddy reload --config /etc/caddy/Caddyfile`.
2. **Container 9Router Tidak Ditemukan oleh Caddy (HTTP 502 Bad Gateway)**:
   - Penyebab: Container `9router` dan `caddy-proxy` tidak berada di Docker network yang sama.
   - Solusi: Pastikan `docker-compose.vps.yml` mendefinisikan network eksternal `proxy-network` dan container 9Router bergabung ke dalamnya.
3. **Deployment Actions Gagal (SSH Authentication Error)**:
   - Verifikasi secret `VPS_SSH_KEY` pada repositori GitHub.
   - Uji koneksi SSH manual dari PowerShell: `ssh -i ~/.ssh/id_oracle_vps ubuntu@129.225.1.91`.
