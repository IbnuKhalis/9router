# Directive: GitHub Push & Version Control SOP

## Goal
Menjalankan alur commit dan push kode ke repositori GitHub secara aman dan terstandar, menjamin tidak ada secret atau kredensial yang bocor, dan menegakkan prinsip *Git as Single Source of Truth*.

---

## Required Inputs
- Modifikasi kode atau dokumentasi yang telah diverifikasi secara lokal.
- Branch Git target (umumnya `master` atau `main`).
- Repositori remote GitHub terhubung (`git remote -v`).

---

## Tools & Execution Scripts
- `git status`, `git diff`, `git add`, `git commit`, `git push`.
- GitHub CLI (`gh`).

---

## Step-by-Step Procedure

### 1. Periksa Status Berkas & Secret Scan
Sebelum menambahkan berkas ke staging, verifikasi bahwa tidak ada berkas sensitif yang belum diabaikan:
```powershell
git status
```
**Wajib diperiksa**:
- Pastikan `.env` **TIDAK** muncul di untracked files atau changes to be committed.
- Pastikan direktori `data/` atau berkas `*.sqlite` tidak ikut terpantau.
- Pastikan tidak ada API key atau password admin yang ditulis langsung di berkas Markdown atau YAML.

### 2. Tinjau Diff Perubahan
Periksa perubahan secara presisi:
```powershell
git diff
```
Pastikan hanya perubahan yang relevan dengan tugas yang dimodifikasi (hindari refactor liar atau perubahan whitespace yang tidak perlu).

### 3. Stage Berkas Terpilih
Tambahkan berkas secara eksplisit atau menyeluruh jika seluruh perubahan sudah terverifikasi:
```powershell
git add docs/ directives/ execution/ AGENTS.md CLAUDE.md GEMINI.md TODO.md .github/ .env.example docker-compose.yml docker-compose.vps.yml
```

### 4. Buat Commit dengan Pesan Deskriptif
Gunakan format konvensional yang jelas:
```powershell
git commit -m "docs: restructure project layout according to Agent Instructions.md"
```

### 5. Push ke Remote Repository
Kirimkan commit ke remote repository (standar branch: `main`):
```powershell
# Jika repositori lokal masih di branch master, selaraskan dengan: git branch -M main
git push -u origin main
```

---

## Expected Outputs
- Commit tercatat bersih di riwayat git.
- Repositori remote GitHub ter-update.
- Pipeline GitHub Actions otomatis terpicu jika ada perubahan yang menargetkan alur deployment.

---

## Important Constraints
- **Zero Secrets**: Dilarang memaksa penambahan berkas `.env` (`git add -f .env`).
- **Pre-Verification**: Dilarang melakukan push perubahan konfigurasi docker tanpa verifikasi lokal terlebih dahulu.

---

## Known Edge Cases & Recovery
1. **Secret Tidak Sengaja Masuk ke Staging**:
   - Batalkan staging segera: `git restore --staged <file>`
   - Pastikan entri tersebut sudah terdaftar di `.gitignore`.
2. **Push Ditolak Karena Konflik Remote (Non-Fast-Forward)**:
   - Ambil update terbaru: `git fetch origin`
   - Rebase atau merge dengan hati-hati: `git pull --rebase origin master`
   - Uji ulang lokal sebelum push kembali.
