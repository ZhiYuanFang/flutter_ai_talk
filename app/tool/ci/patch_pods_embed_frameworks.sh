#!/usr/bin/env bash
# [CP] Embed Pods Frameworks 在 Archive 时会对 CwlCatchException 等 framework 重签名；
# Flutter/CocoaPods 产物可能为只读，导致 codesign Permission denied。
# 在 embed 脚本中 codesign 前 chmod +w（幂等标记 CI_PATCH_CODESIGN_CHMOD）。
set -euo pipefail

cd "$(dirname "$0")/../.."
FRAMEWORKS_SH="ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh"

if [[ ! -f "$FRAMEWORKS_SH" ]]; then
  echo "skip: $FRAMEWORKS_SH 不存在（尚未 pod install）"
  exit 0
fi

if grep -q 'CI_PATCH_CODESIGN_CHMOD' "$FRAMEWORKS_SH"; then
  echo "Pods-Runner-frameworks.sh: chmod patch 已存在"
  exit 0
fi

python3 <<'PY'
from pathlib import Path
import sys

path = Path("ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh")
text = path.read_text(encoding="utf-8")
markers = [
    'echo "Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}"',
    "echo \"Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}\"",
]
for marker in markers:
    if marker in text:
        insert = (
            marker
            + '\n    chmod -R +w "$1" 2>/dev/null || true  # CI_PATCH_CODESIGN_CHMOD'
        )
        path.write_text(text.replace(marker, insert, 1), encoding="utf-8")
        print("Patched Pods-Runner-frameworks.sh: chmod before codesign")
        sys.exit(0)

print("warning: Pods-Runner-frameworks.sh layout unexpected; skip chmod patch", file=sys.stderr)
PY
