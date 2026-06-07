# Simulates enough errors to trigger the CRITICAL Prometheus alert (> 5 errors/min)
$baseUrl = "http://localhost:5000"
$errorCount = 10

Write-Host "Generating $errorCount errors to trigger CRITICAL alert..."
for ($i = 1; $i -le $errorCount; $i++) {
    Invoke-WebRequest -Uri "$baseUrl/api/error?type=alert_simulation" -UseBasicParsing | Out-Null
    Write-Host "  Error $i/$errorCount sent"
}

Write-Host ""
Write-Host "Done. Wait 1-2 minutes, then verify:"
Write-Host "  Prometheus alerts: http://localhost:9090/alerts"
Write-Host "  Grafana alerting:  http://localhost:3000/alerting/list (admin/admin)"
