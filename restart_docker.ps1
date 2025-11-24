# Script to restart Docker Desktop

Write-Host "Stopping Docker Desktop processes..." -ForegroundColor Yellow

# Stop Docker Desktop processes
Get-Process -Name "*Docker*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Starting Docker Desktop..." -ForegroundColor Green

# Start Docker Desktop as administrator
$dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Start-Process $dockerPath -Verb RunAs
    Write-Host "Docker Desktop launched! Please wait 3-5 minutes for it to fully initialize." -ForegroundColor Green
    Write-Host "Look for the Docker whale icon in your system tray (bottom-right)." -ForegroundColor Cyan
} else {
    Write-Host "Docker Desktop not found. Please start it manually from Start menu." -ForegroundColor Red
}






