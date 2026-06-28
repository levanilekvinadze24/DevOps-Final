$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

Write-Host "=== DevOps Observability Lab - Environment Setup ==="

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed. Install Docker Desktop first."
}

docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker Desktop is not running. Start Docker Desktop and try again."
}

docker compose version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker Compose v2 is required."
}

if (-not (Test-Path ".env")) {
    Write-Host "Creating .env from .env.example..."
    Copy-Item ".env.example" ".env"
}

Write-Host "Building and starting the full observability stack..."
docker compose down --remove-orphans 2>$null
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker Compose failed. If you see name conflicts, run: docker compose down --remove-orphans"
}

Write-Host "Waiting for services to become healthy..."
& "$RootDir\scripts\validate-environment.ps1"

Write-Host ""
Write-Host "Setup complete. Services:"
Write-Host "  Application:   http://localhost:5000"
Write-Host "  Prometheus:    http://localhost:9090"
Write-Host "  Grafana:       http://localhost:3000  (admin/admin)"
Write-Host "  Alertmanager:  http://localhost:9093"
Write-Host "  Loki:          http://localhost:3100"
