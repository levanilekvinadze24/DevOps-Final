$AppUrl = if ($env:APP_URL) { $env:APP_URL } else { "http://localhost:5000" }
$Interval = if ($env:INTERVAL) { [int]$env:INTERVAL } else { 30 }
$MaxFailures = if ($env:MAX_FAILURES) { [int]$env:MAX_FAILURES } else { 3 }

$failures = 0

Write-Host "Monitoring $AppUrl/health every ${Interval}s (max failures: $MaxFailures)"
Write-Host "Press Ctrl+C to stop."

while ($true) {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    try {
        $health = Invoke-WebRequest -Uri "$AppUrl/health" -UseBasicParsing -TimeoutSec 5
        $ready = Invoke-WebRequest -Uri "$AppUrl/ready" -UseBasicParsing -TimeoutSec 5
        if ($health.StatusCode -eq 200 -and $ready.StatusCode -eq 200) {
            $failures = 0
            Write-Host "[$timestamp] HEALTHY"
        } else {
            throw "Non-200 response"
        }
    } catch {
        $failures++
        Write-Host "[$timestamp] UNHEALTHY ($failures/$MaxFailures)"
        if ($failures -ge $MaxFailures) {
            Write-Host "ALERT: Service failed $MaxFailures consecutive checks."
            Write-Host "Suggested action: docker compose logs app --tail=50"
            $failures = 0
        }
    }
    Start-Sleep -Seconds $Interval
}
