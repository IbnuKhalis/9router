# AGENTS.md — 9Router AI Gateway

> Berkas ini adalah cermin operasional dari [`agent.md`](file:///d:/Antigravity/9router/agent.md).

Lihat petunjuk lengkap, arsitektur 3 lapis, invariant lingkungan (Windows PowerShell & Oracle Cloud ARM64), serta standar keamanan di:
👉 [**agent.md**](file:///d:/Antigravity/9router/agent.md)

## Aturan Ringkas Agen AI:
1. **Lokal Dulu, VPS Kemudian**: Selesaikan seluruh verifikasi fungsional di lingkungan lokal Windows sebelum melakukan deployment ke VPS.
2. **Git sebagai Single Source of Truth**: Dilarang live-edit langsung di server VPS `vps-main`.
3. **PowerShell Windows & Encoding**: Jangan gunakan `&&`; gunakan `;` untuk pemisah perintah. Berkas `.env` wajib dibuat via `.\scripts\init-env.ps1` agar UTF-8 No BOM aman di Linux container.
4. **Dual-Volume Persistence**: Pastikan volume `/app/data` dan `/root/.9router` selalu terpetakan agar riwayat token dan log tidak terhapus saat container restart.
5. **Keamanan Kredensial**: Jaga kerahasiaan `.env`, jangan commit secret ke repositori.
6. **Living Document**: Perbarui berkas [`TODO.md`](file:///d:/Antigravity/9router/TODO.md) setiap kali tahapan selesai atau terdapat keputusan arsitektur baru.

