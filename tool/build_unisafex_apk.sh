#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  cat <<'EOF'
Missing .env.local

Create it from the example:
  cp .env.local.example .env.local

Then paste your Supabase anon/publishable key:
  SUPABASE_ANON_KEY=...

Find it in Supabase Dashboard > Project Settings > API.
EOF
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "SUPABASE_URL and SUPABASE_ANON_KEY are required in .env.local"
  exit 1
fi

flutter build apk --release \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
  "$@"
