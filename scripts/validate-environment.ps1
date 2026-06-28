$ErrorActionPreference = "Stop"
$AppUrl = if ($env:APP_URL) { $env:APP_URL } else { "http://localhost:5000" }
$MaxAttempts = if ($env:MAX_ATTEMPTS) { [int]$env:MAX_ATTEMPTS } else { 30 }
$SleepSeconds = if ($env:SLEEP_SECONDS) { [int]$env:SLEEP_SECONDS } else { 5 }

Write-Host "=== Environment Validation ==="

function Wait-ServiceUrl {
    param(
        [string]$Name,
        [string]$Url,
        [int]$Attempts = $MaxAttempts
    )

    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Host "  [OK] $Name"
                return
            }
        } catch {}

        if ($i -lt $Attempts) {
            Write-Host "  Waiting for $Name... ($i/$Attempts)"
            Start-Sleep -Seconds $SleepSeconds
        }
    }

    Write-Error "$Name failed validation ($Url)"
}

$attempt = 1
$appReady = $false
while ($attempt -le $MaxAttempts) {
    try {
        $health = Invoke-WebRequest -Uri "$AppUrl/health" -UseBasicParsing -TimeoutSec 10
        $ready = Invoke-WebRequest -Uri "$AppUrl/ready" -UseBasicParsing -TimeoutSec 10
        $metrics = Invoke-WebRequest -Uri "$AppUrl/metrics" -UseBasicParsing -TimeoutSec 10
        if ($health.StatusCode -eq 200 -and $ready.StatusCode -eq 200 -and $metrics.Content -match "app_requests_total") {
            Write-Host "  [OK] Application health, readiness, and metrics"
            $appReady = $true
            break
        }
    } catch {}
    Write-Host "  Waiting for application... ($attempt/$MaxAttempts)"
    $attempt++
    Start-Sleep -Seconds $SleepSeconds
}

if (-not $appReady) {
    Write-Error "Application failed validation."
}

Wait-ServiceUrl "Prometheus" "http://localhost:9090/-/healthy"
Wait-ServiceUrl "Alertmanager" "http://localhost:9093/-/healthy"
Wait-ServiceUrl "Grafana" "http://localhost:3000/api/health" -Attempts 36
Wait-ServiceUrl "Loki" "http://localhost:3100/ready"

Write-Host ""
Write-Host "All services validated successfully."
