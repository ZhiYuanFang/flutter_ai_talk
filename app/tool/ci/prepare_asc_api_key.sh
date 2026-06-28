#!/usr/bin/env bash
# Prepare App Store Connect API key (.p8 + fastlane JSON).
# Writes APP_STORE_CONNECT_API_KEY_JSON to GITHUB_ENV when set.
set -euo pipefail

KEY_PATH="${ASC_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8}"
API_KEY_JSON_PATH="${ASC_API_KEY_JSON_PATH:-$RUNNER_TEMP/app_store_connect_api_key.json}"

mkdir -p "$(dirname "$KEY_PATH")"

KEY_PATH="$KEY_PATH" python3 <<'PY'
import base64
import os
from pathlib import Path

Path(os.environ['KEY_PATH']).write_bytes(
    base64.b64decode(os.environ['APP_STORE_CONNECT_API_KEY_P8_BASE64'])
)
PY

chmod 600 "$KEY_PATH"

KEY_PATH="$KEY_PATH" \
  API_KEY_JSON_PATH="$API_KEY_JSON_PATH" \
  APP_STORE_CONNECT_KEY_ID="$APP_STORE_CONNECT_KEY_ID" \
  APP_STORE_CONNECT_ISSUER_ID="$APP_STORE_CONNECT_ISSUER_ID" \
  python3 <<'PY'
import json
import os
from pathlib import Path

key = Path(os.environ['KEY_PATH']).read_text(encoding='utf-8')
payload = {
    'key_id': os.environ['APP_STORE_CONNECT_KEY_ID'],
    'issuer_id': os.environ['APP_STORE_CONNECT_ISSUER_ID'],
    'key': key,
    'in_house': False,
}
Path(os.environ['API_KEY_JSON_PATH']).write_text(json.dumps(payload), encoding='utf-8')
PY

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "APP_STORE_CONNECT_API_KEY_JSON=$API_KEY_JSON_PATH" >> "$GITHUB_ENV"
fi

echo "[ASC] prepared api_key_path=$API_KEY_JSON_PATH"
