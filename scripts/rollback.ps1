$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

$ImageName = if ($env:IMAGE_NAME) { $env:IMAGE_NAME } else { "observability-lab-app:latest" }
$BackupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { ".deploy-backups" }

Write-Host "=== Rollback - Observability Lab ==="

$latestBackup = Get-ChildItem -Path $BackupDir -Filter "image-*.txt" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latestBackup) {
    Write-Error "No deployment backup found. Run deploy.ps1 first to create a rollback point."
}

$previousImage = (Get-Content $latestBackup.FullName -Raw).Trim()
Write-Host "Rolling back to: $previousImage (from $($latestBackup.Name))"

if (-not (docker image inspect $previousImage 2>$null)) {
    Write-Error "Rollback image '$previousImage' not found locally. Cannot roll back."
}

docker compose stop app
docker tag $previousImage $ImageName
docker compose up -d --no-build app

& "$RootDir\scripts\validate-environment.ps1"
Write-Host "Rollback completed."
