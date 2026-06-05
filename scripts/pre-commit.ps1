$ErrorActionPreference = "Stop"

$Root = git rev-parse --show-toplevel
Set-Location $Root

$detectSecrets = Get-Command detect-secrets -ErrorAction SilentlyContinue
if (-not $detectSecrets) {
    Write-Host "detect-secrets no está instalado."
    Write-Host "Instalá con: pip install detect-secrets"
    exit 1
}

$staged = git diff --cached --name-only --diff-filter=ACM
if (-not $staged) {
    exit 0
}

detect-secrets-hook --baseline .secrets.baseline --exclude-files '(?x)(^supabase/config\.toml$)' @staged
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
