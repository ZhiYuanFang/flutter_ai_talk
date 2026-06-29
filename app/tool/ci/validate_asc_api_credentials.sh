#!/usr/bin/env bash
# Probe App Store Connect API credentials before the expensive IPA build.
set -euo pipefail

if ! command -v fastlane >/dev/null 2>&1; then
  echo '[ASC] installing fastlane for credential probe'
  sudo gem install fastlane -N
fi

bash tool/ci/prepare_asc_api_key.sh

API_KEY_JSON="${APP_STORE_CONNECT_API_KEY_JSON:-$RUNNER_TEMP/app_store_connect_api_key.json}"
if [[ ! -f "$API_KEY_JSON" ]]; then
  echo '::error::[ASC] 未生成 API key JSON，请检查 APP_STORE_CONNECT_* Secrets'
  exit 1
fi

if [[ -z "${IOS_BUNDLE_ID:-}" ]]; then
  echo '::error::[ASC] 缺少 IOS_BUNDLE_ID，无法探活 App Store Connect'
  exit 1
fi

set +e
output="$(
  fastlane pilot builds \
    --api_key_path "$API_KEY_JSON" \
    --app_identifier "$IOS_BUNDLE_ID" \
    2>&1
)"
probe_status=$?

if [[ "$probe_status" -ne 0 ]]; then
  if echo "$output" | grep -Eqi 'UnauthorizedAccessError|Authentication credentials are missing or invalid'; then
    echo '::error::[ASC] API 鉴权失败 — 请检查 APP_STORE_CONNECT_KEY_ID、APP_STORE_CONNECT_ISSUER_ID、APP_STORE_CONNECT_API_KEY_P8_BASE64 是否为同一把有效 Key（.p8 只能下载一次，Revoke 后须更新 Secret）'
    echo '::error::[ASC] 参考: App Store Connect → 用户和访问 → 集成 → App Store Connect API'
    exit 1
  fi
  if echo "$output" | grep -Eqi "Couldn't find app|Could not find app"; then
    echo "::error::[ASC] API 鉴权通过，但 App Store Connect 未找到 App: IOS_BUNDLE_ID=$IOS_BUNDLE_ID"
    echo '::error::[ASC] 请先在 App Store Connect 创建对应 Bundle ID 的 App 记录'
    exit 1
  fi
  echo "::warning::[ASC] 探活命令非预期退出 exit_status=${probe_status}，继续构建（上传阶段可能仍会失败）"
  echo "$output" | tail -n 20
  exit 0
fi

set -e
echo '::notice::[ASC] API 鉴权探活通过'
