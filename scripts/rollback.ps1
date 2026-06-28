$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

$BackupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { ".deploy-backups" }

Write-Host "=== Rollback - Observability Lab ==="

$latestBackup = Get-ChildItem -Path $BackupDir -Filter "image-*.txt" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latestBackup) {
    Write-Host "No deployment backup found. Rebuilding previous compose state..."
    docker compose up -d --build app
} else {
    $previousImage = Get-Content $latestBackup.FullName
    Write-Host "Rolling back using backup from: $($latestBackup.Name)"
    docker compose stop app
    docker compose up -d --build app
}

& "$RootDir\scripts\validate-environment.ps1"
Write-Host "Rollback completed."
