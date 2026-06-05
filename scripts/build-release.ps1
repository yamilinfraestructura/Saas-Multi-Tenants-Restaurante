$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $Root "apps\shell_app")

Write-Host "==> Build Web"
flutter build web --release

Write-Host "==> Build Windows"
flutter build windows --release

Write-Host "==> Build APK"
flutter build apk --release

Write-Host "Builds completados en apps/shell_app/build/"
