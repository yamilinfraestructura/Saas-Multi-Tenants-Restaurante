$ErrorActionPreference = "Stop"

$Root = git rev-parse --show-toplevel
$HooksDir = Join-Path $Root ".git\hooks"
$HookPath = Join-Path $HooksDir "pre-commit"

if (-not (Test-Path $HooksDir)) {
    Write-Error "No se encontró .git/hooks. ¿Estás en un repositorio git?"
}

$HookContent = @"
#!/bin/sh
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$Root/scripts/pre-commit.ps1"
"@

Set-Content -Path $HookPath -Value $HookContent -Encoding ASCII
Write-Host "Hook pre-commit instalado en $HookPath"
