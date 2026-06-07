# Generates normal application traffic for dashboard metrics
$baseUrl = "http://localhost:5000"
$iterations = 20

Write-Host "Generating normal traffic ($iterations requests)..."
for ($i = 1; $i -le $iterations; $i++) {
    Invoke-WebRequest -Uri "$baseUrl/api/data" -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing | Out-Null
    Write-Host "  Request batch $i/$iterations"
    Start-Sleep -Milliseconds 500
}

Write-Host "Done. Check Grafana dashboard at http://localhost:3000"
