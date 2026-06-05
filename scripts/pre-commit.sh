#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if ! command -v detect-secrets >/dev/null 2>&1; then
  echo "detect-secrets no está instalado."
  echo "Instalá con: pip install detect-secrets"
  exit 1
fi

detect-secrets-hook --baseline .secrets.baseline --exclude-files '(?x)(^supabase/config\.toml$)' "$@"
