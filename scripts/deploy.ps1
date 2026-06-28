$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

$ImageTag = if ($env:IMAGE_TAG) { $env:IMAGE_TAG } else { "latest" }
$BackupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { ".deploy-backups" }

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupFile = Join-Path $BackupDir "image-$Timestamp.txt"

Write-Host "=== Deploy - Observability Lab ==="

$running = docker compose ps app --format json 2>$null
if ($running -match '"State":"running"') {
    $currentImage = docker inspect observability-lab-app --format='{{.Config.Image}}' 2>$null
    if ($currentImage) {
        Set-Content -Path $BackupFile -Value $currentImage
        Write-Host "Saved rollback reference: $currentImage -> $BackupFile"
    }
}

Write-Host "Building and deploying app (tag: $ImageTag)..."
docker compose build app
docker compose up -d app

Write-Host "Running post-deployment validation..."
& "$RootDir\scripts\validate-environment.ps1"

Write-Host "Deploy completed successfully."
