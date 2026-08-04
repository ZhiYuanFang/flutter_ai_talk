#!/usr/bin/env bash
# 从仓库根 .fvmrc 解析 Flutter 版本（单一真源）。
# 用法：resolve_flutter_version.sh [requested]
# - requested 为空或 "pinned" → 输出 .fvmrc 中的版本
# - 否则输出 requested（允许 CI 手动覆盖做升级试验）
set -euo pipefail

# app/tool/ci → 仓库根
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FVMRC="$ROOT/.fvmrc"

if [[ ! -f "$FVMRC" ]]; then
  echo "::error::缺少 $FVMRC（Flutter 版本真源）" >&2
  exit 1
fi

PINNED="$(python3 -c "import json; print(json.load(open(r'$FVMRC'))['flutter'].strip())")"
REQUESTED="${1:-}"

if [[ -z "$REQUESTED" || "$REQUESTED" == "pinned" ]]; then
  echo "$PINNED"
else
  echo "$REQUESTED"
fi
