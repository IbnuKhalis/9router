# Directive: Local Setup & Initialization

## Goal
Inisialisasi lingkungan lokal Windows, siapkan konfigurasi berkas `.env` dengan encoding aman (UTF-8 No BOM), jalankan container Docker 9Router secara lokal, dan pastikan dashboard dapat diakses pada port 20128.

---

## Required Inputs
- Docker Desktop aktif pada host Windows 11.
- Berkas template `.env.example`.
- Hak eksekusi PowerShell di terminal lokal.

---

## Tools & Execution Scripts
- `execution/init-env.ps1`: Skrip deterministik untuk membuat `.env` dan folder data persisten.
- `docker compose up -d`: Orkestrasi container Docker lokal.
- `execution/test-connection.ps1`: Skrip diagnostik konektivitas lokal.

---

## Step-by-Step Procedure

### 1. Inisialisasi Berkas Konfigurasi
Jalankan skrip inisialisasi deterministik:
```powershell
.\execution\init-env.ps1
```
*Catatan: Skrip ini menghasilkan `JWT_SECRET` acak dan `INITIAL_PASSWORD` baru, serta membuat folder `data/` dan `data/.9router/`.*

### 2. Validasi Docker Engine
Pastikan daemon Docker Desktop berjalan:
```powershell
docker info
```

### 3. Jalankan Container 9Router
Start container menggunakan Docker Compose:
```powershell
docker compose up -d
```

### 4. Periksa Status dan Log Container
Pastikan container berjalan tanpa restart loop:
```powershell
docker compose ps
docker compose logs --tail 25 9router
```

### 5. Verifikasi Konektivitas
Jalankan diagnostik awal:
```powershell
.\execution\test-connection.ps1
```

---

## Expected Outputs
- Berkas `.env` dibuat dengan encoding UTF-8 No BOM.
- Direktori `./data` dan `./data/.9router` siap.
- Container `9router` berstatus `Up` pada port `0.0.0.0:20128->20128/tcp`.
- Dashboard web dapat dibuka di browser: `http://localhost:20128`.

---

## Important Constraints
- **Encoding**: Dilarang mengedit berkas `.env` dengan editor yang menyisipkan UTF-8 BOM. Gunakan `execution/init-env.ps1`.
- **PowerShell Syntax**: Jangan gunakan operator `&&`; gunakan titik koma `;` atau baris terpisah.
- **Port Conflict**: Port `20128` harus bebas dari proses lain.

---

## Known Edge Cases & Recovery
1. **Port 20128 Already in Use**:
   - Deteksi proses: `Get-NetTCPConnection -LocalPort 20128 -ErrorAction SilentlyContinue`
   - Hentikan proses yang memblokir atau ubah port host pada `docker-compose.yml`.
2. **Container Exit Status 1 / SQLite Lock**:
   - Periksa izin folder `data/`.
   - Jalankan `docker compose down` dan pastikan tidak ada proses container yang tertinggal.
3. **Lupa Password Awal Dashboard**:
   - Jika belum login, jalankan `.\execution\init-env.ps1 -Force -InitialPassword "passwordBaru123!"` lalu restart container: `docker compose restart 9router`.
