[CmdletBinding()]
param(
    [Parameter()]
    [string]$BaseUrl = "http://localhost:20128",

    [Parameter()]
    [string]$ApiKey = "",

    [Parameter()]
    [string]$Model = "auto",

    [Parameter()]
    [switch]$SendChatPrompt
)

$ErrorActionPreference = "Continue"

$BaseUrl = $BaseUrl.TrimEnd('/')

Write-Host "`n=== 9Router Connection & API Diagnostic Tool ===" -ForegroundColor Cyan
Write-Host "Target Endpoint: $BaseUrl`n" -ForegroundColor DarkGray

# 1. Test Dashboard / Root Web Connectivity
Write-Host "[1/3] Menguji konektivitas Dashboard ($BaseUrl)..." -NoNewline
try {
    $Response = Invoke-WebRequest -Uri $BaseUrl -Method GET -TimeoutSec 5 -UseBasicParsing
    if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 400) {
        Write-Host " [OK] (HTTP $($Response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host " [WARNING] (HTTP $($Response.StatusCode))" -ForegroundColor Yellow
    }
} catch {
    Write-Host " [FAILED]" -ForegroundColor Red
    Write-Host "      Pesan Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    Write-Host "      Solusi: Pastikan container docker berjalan dengan 'docker compose ps'." -ForegroundColor Yellow
    return
}

# 2. Test /v1/models Endpoint
Write-Host "[2/3] Menguji endpoint OpenAI-compatible ($BaseUrl/v1/models)..." -NoNewline
$Headers = @{}
if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    $Headers["Authorization"] = "Bearer $ApiKey"
}

try {
    $ModelsResp = Invoke-RestMethod -Uri "$BaseUrl/v1/models" -Method GET -Headers $Headers -TimeoutSec 10
    Write-Host " [OK]" -ForegroundColor Green
    
    $Count = 0
    if ($ModelsResp.data) {
        $Count = ($ModelsResp.data).Count
        Write-Host "      Ditemukan $Count model terdaftar." -ForegroundColor Cyan
        $SampleModels = ($ModelsResp.data | Select-Object -First 5 | ForEach-Object { $_.id }) -join ", "
        if ($SampleModels) {
            Write-Host "      Contoh model: $SampleModels" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "      Endpoint merespons, namun belum ada provider/model yang terhubung di dashboard." -ForegroundColor Yellow
    }
} catch {
    $StatusCode = $null
    if ($_.Exception.Response) {
        try {
            $StatusCode = [int]$_.Exception.Response.StatusCode
        } catch {
            $StatusCode = $null
        }
    }

    if ($StatusCode -eq 401) {
        Write-Host " [PROTECTED] (HTTP 401 Unauthorized)" -ForegroundColor Yellow
        Write-Host "      Endpoint ini memerlukan API Key. Jalankan dengan: .\execution\test-connection.ps1 -ApiKey 'sk-...'" -ForegroundColor Yellow
    } elseif ($StatusCode) {
        Write-Host " [FAILED] (HTTP $StatusCode)" -ForegroundColor Red
        Write-Host "      Pesan Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    } else {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "      Pesan Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    }
}

# 3. Test /v1/chat/completions Prompt (Opsional jika -SendChatPrompt diaktifkan)
if ($SendChatPrompt) {
    Write-Host "[3/3] Menguji Chat Completion ($BaseUrl/v1/chat/completions) dengan model '$Model'..." -NoNewline
    $Body = @{
        model = $Model
        messages = @(
            @{ role = "user"; content = "Halo 9Router, tes konektivitas satu kata!" }
        )
        max_tokens = 20
    } | ConvertTo-Json -Compress

    $ReqHeaders = @{
        "Content-Type" = "application/json"
    }
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $ReqHeaders["Authorization"] = "Bearer $ApiKey"
    }

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $ChatResp = Invoke-RestMethod -Uri "$BaseUrl/v1/chat/completions" -Method POST -Headers $ReqHeaders -Body $Body -TimeoutSec 30
        $Stopwatch.Stop()
        Write-Host " [OK] ($($Stopwatch.ElapsedMilliseconds)ms)" -ForegroundColor Green

        if ($ChatResp.choices -and $ChatResp.choices.Count -gt 0 -and $ChatResp.choices[0].message) {
            $Reply = $ChatResp.choices[0].message.content
            Write-Host "      Respons: $Reply" -ForegroundColor Cyan
        } else {
            $RawSummary = ($ChatResp | ConvertTo-Json -Compress)
            if ($RawSummary.Length -gt 120) { $RawSummary = $RawSummary.Substring(0, 120) + "..." }
            Write-Host "      Respons diterima: $RawSummary" -ForegroundColor Yellow
        }

        if ($ChatResp.usage) {
            Write-Host "      Token Usage: prompt=$($ChatResp.usage.prompt_tokens), completion=$($ChatResp.usage.completion_tokens), total=$($ChatResp.usage.total_tokens)" -ForegroundColor DarkGray
        }
    } catch {
        $Stopwatch.Stop()
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "      Pesan Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    }
} else {
    Write-Host "[3/3] Uji chat completion dilewati. Gunakan flag -SendChatPrompt untuk menguji pengiriman prompt ke model AI." -ForegroundColor DarkGray
}

Write-Host "`nDiagnostik selesai.`n" -ForegroundColor Cyan
