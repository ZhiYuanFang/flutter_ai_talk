#!/usr/bin/env bash
# 包装 flutter build ipa：在 Flutter 调用的每一次 xcodebuild 之前，
# 先对齐 ephemeral Package.swift platforms，避免「FlutterFramework 要 13 / target 却是 12」。
set -euo pipefail

cd "$(dirname "$0")/../.."

ALIGN_SCRIPT="$(cd "$(dirname "$0")" && pwd)/align_spm_ios_platforms.sh"
WRAP_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/pangbao_xcodebuild_spm_align_$$"
mkdir -p "$WRAP_DIR"

cleanup() {
  rm -rf "$WRAP_DIR"
}
trap cleanup EXIT

cat >"$WRAP_DIR/xcodebuild" <<EOF
#!/bin/bash
set -euo pipefail
# Flutter 可能在启动 xcodebuild 前刚重写 Package.swift；此处再抬一次 platforms
/bin/bash "$ALIGN_SCRIPT" || true
exec /usr/bin/xcodebuild "\$@"
EOF
chmod +x "$WRAP_DIR/xcodebuild"

export PATH="$WRAP_DIR:$PATH"
exec flutter build ipa "$@"
