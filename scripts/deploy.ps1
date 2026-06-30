$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

$ImageName = if ($env:IMAGE_NAME) { $env:IMAGE_NAME } else { "observability-lab-app:latest" }
$BackupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { ".deploy-backups" }

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupFile = Join-Path $BackupDir "image-$Timestamp.txt"
$RollbackTag = "observability-lab-app:rollback-$Timestamp"

Write-Host "=== Deploy - Observability Lab ==="

$running = docker compose ps app --format json 2>$null
if ($running -match '"State":"running"') {
    if (docker image inspect $ImageName 2>$null) {
        docker tag $ImageName $RollbackTag
        Set-Content -Path $BackupFile -Value $RollbackTag
        Write-Host "Saved rollback image: $RollbackTag -> $BackupFile"
    }
}

Write-Host "Building and deploying app..."
docker compose build app
docker compose up -d app

Write-Host "Running post-deployment validation..."
& "$RootDir\scripts\validate-environment.ps1"

Write-Host "Deploy completed successfully."
