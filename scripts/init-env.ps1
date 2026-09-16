[CmdletBinding()]
param(
    [Parameter()]
    [string]$InitialPassword = "",

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$RootPath = (Get-Item $PSScriptRoot).Parent.FullName
$EnvExamplePath = Join-Path $RootPath ".env.example"
$EnvPath = Join-Path $RootPath ".env"
$DataDir = Join-Path $RootPath "data"
$Root9RouterDir = Join-Path $DataDir ".9router"

Write-Host "=== 9Router Environment Initializer ===" -ForegroundColor Cyan

# 1. Pastikan folder persistensi lokal ada
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
    Write-Host "[OK] Direktori data dibuat: $DataDir" -ForegroundColor Green
}

if (-not (Test-Path $Root9RouterDir)) {
    New-Item -ItemType Directory -Path $Root9RouterDir -Force | Out-Null
    Write-Host "[OK] Direktori stats persistensi dibuat: $Root9RouterDir" -ForegroundColor Green
}

# 2. Validasi berkas .env
if ((Test-Path $EnvPath) -and (-not $Force)) {
    Write-Host "[SKIP] Berkas .env sudah ada. Gunakan -Force jika ingin menulis ulang." -ForegroundColor Yellow
    return
}

if (-not (Test-Path $EnvExamplePath)) {
    Write-Error "Template .env.example tidak ditemukan di $EnvExamplePath"
    return
}

# 3. Generate JWT_SECRET acak berkekuatan tinggi
$RngBytes = New-Object byte[] 32
$Rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$Rng.GetBytes($RngBytes)
$JwtSecret = [Convert]::ToBase64String($RngBytes)

# 4. Tentukan INITIAL_PASSWORD
if ([string]::IsNullOrWhiteSpace($InitialPassword)) {
    # Buat password acak 14 karakter yang aman
    $PassBytes = New-Object byte[] 10
    $Rng.GetBytes($PassBytes)
    $InitialPassword = [Convert]::ToBase64String($PassBytes).Replace("+", "A").Replace("/", "B").Substring(0, 10) + "!9R"
}

# 5. Baca template dan ganti placeholder
$Content = Get-Content -Path $EnvExamplePath -Raw
$Content = $Content -replace "JWT_SECRET=ganti-dengan-string-acak-panjang-dan-aman", "JWT_SECRET=$JwtSecret"
$Content = $Content -replace "INITIAL_PASSWORD=ganti-dengan-password-admin-anda", "INITIAL_PASSWORD=$InitialPassword"

# 6. Tulis berkas .env dengan encoding UTF-8 TANPA BOM (Aman untuk Linux Docker)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($EnvPath, $Content, $Utf8NoBom)

Write-Host "[SUCCESS] Berkas .env berhasil dibuat!" -ForegroundColor Green
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Dashboard URL    : http://localhost:20128" -ForegroundColor White
Write-Host "  Initial Password : $InitialPassword" -ForegroundColor Yellow
Write-Host "  JWT Secret       : [Generated $(($JwtSecret).Length) chars]" -ForegroundColor DarkGray
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Simpan password di atas untuk login pertama kali ke dashboard 9Router." -ForegroundColor Cyan
