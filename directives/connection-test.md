# Directive: Connection & API Diagnostics

## Goal
Memverifikasi fungsionalitas gateway 9Router, menguji ketersediaan Web UI Dashboard, memeriksa registrasi model AI pada endpoint OpenAI-compatible (`/v1/models`), dan memvalidasi pengiriman prompt chat completion (`/v1/chat/completions`).

---

## Required Inputs
- Target Base URL (Default lokal: `http://localhost:20128`, Default VPS: `https://router.digitalneeds.my.id`).
- API Key (Wajib jika `REQUIRE_API_KEY=true` atau saat menguji VPS).
- Model alias target (Default: `auto`).

---

## Tools & Execution Scripts
- `execution/test-connection.ps1`: Skrip deterministik diagnostik 3 tahap.

---

## Step-by-Step Procedure

### 1. Uji Konektivitas Dashboard & Status Dasar
Jalankan pengujian tanpa parameter untuk target lokal default:
```powershell
.\execution\test-connection.ps1
```
*Tindakan*: Memeriksa HTTP GET ke root `/` dan endpoint `/v1/models` tanpa API key.

### 2. Uji Endpoint Model dengan API Key
Setelah API key dibuat di menu **API Keys** pada dashboard 9Router:
```powershell
.\execution\test-connection.ps1 -ApiKey "<MASTER_API_KEY>"
```
*Ekspektasi*: Mengembalikan daftar model yang terhubung (contoh: `kr/claude-sonnet-4.5`, `opencode/gpt-4o-mini`, `gemini-2.0-flash`).

### 3. Uji Pengiriman Chat Completion (Live Prompt)
Kirimkan prompt uji coba ke model untuk memvalidasi alur routing dan respons LLM:
```powershell
.\execution\test-connection.ps1 -ApiKey "<MASTER_API_KEY>" -Model "auto" -SendChatPrompt
```
*Ekspektasi*: Menerima respons teks valid dari LLM beserta metrik waktu respons (`ms`) dan token usage (`prompt_tokens`, `completion_tokens`).

### 4. Uji Endpoint VPS Produksi
Jalankan diagnostik terhadap endpoint HTTPS VPS:
```powershell
.\execution\test-connection.ps1 -BaseUrl "https://router.digitalneeds.my.id" -ApiKey "<VPS_API_KEY>"
```

---

## Expected Outputs
- Tahap 1: HTTP 200 OK pada root dashboard.
- Tahap 2: Daftar model terdaftar dengan ID model yang aktif.
- Tahap 3: Respons chat completion dengan latensi terukur dan status token usage.

---

## Important Constraints
- Jangan memasukkan API key langsung di argumen terminal jika riwayat command line terekspos; gunakan variabel lingkungan atau PowerShell secure string jika diperlukan.
- Endpoint VPS selalu menolak request tanpa header `Authorization: Bearer <API_KEY>` (HTTP 401).

---

## Known Edge Cases & Recovery
1. **HTTP 401 Unauthorized**:
   - Penyebab: Endpoint diproteksi oleh `REQUIRE_API_KEY=true` atau API key salah.
   - Solusi: Buat API key baru di dashboard atau verifikasi string token.
2. **Koneksi Ditolak / Timeout (Connection Refused)**:
   - Penyebab: Container belum berjalan atau port forwarding salah.
   - Solusi: Cek `docker compose ps` dan log container `docker compose logs 9router`.
3. **Endpoint Merespons tapi Model Kosong (`data: []`)**:
   - Penyebab: Belum ada model provider yang didaftarkan di dashboard.
   - Solusi: Buka dashboard di browser, tambahkan provider gratis (Kiro/OpenCode/Gemini), lalu ulangi uji coba.
