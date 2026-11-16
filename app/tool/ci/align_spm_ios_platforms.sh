#!/usr/bin/env bash
# 将 Flutter ephemeral SPM Package.swift 中低于主 App 基线的 .iOS("…") 抬到
# IOS_DEPLOYMENT_TARGET（默认 15.0），消除 FlutterFramework(≥13) vs platforms 12 的
# Target Integrity 失败。已 ≥ 基线的声明不降。
set -euo pipefail

cd "$(dirname "$0")/../.."

target="${IOS_DEPLOYMENT_TARGET:-15.0}"
packages_root="ios/Flutter/ephemeral/Packages"

if [[ ! -d "$packages_root" ]]; then
  echo "align_spm_ios_platforms: 跳过（无 $packages_root，请先 flutter build ios --config-only）"
  exit 0
fi

TARGET="$target" PACKAGES_ROOT="$packages_root" python3 <<'PY'
from __future__ import annotations

import os
import re
from pathlib import Path

target = (os.environ.get("TARGET") or "15.0").strip() or "15.0"
root = Path(os.environ["PACKAGES_ROOT"])


def parse_ver(s: str) -> tuple[int, ...]:
    parts = []
    for p in s.strip().split("."):
        if not p.isdigit():
            break
        parts.append(int(p))
    return tuple(parts) if parts else (0,)


def needs_bump(declared: str, floor: str) -> bool:
    return parse_ver(declared) < parse_ver(floor)


# .iOS("12.0") / .iOS('12.0')
pattern = re.compile(r"""(\.iOS\(\s*)(['"])([^'"]+)(\2\s*\))""")

patched = 0
scanned = 0
for path in sorted(root.rglob("Package.swift")):
    scanned += 1
    text = path.read_text(encoding="utf-8")
    original = text

    def repl(m: re.Match[str]) -> str:
        declared = m.group(3)
        if needs_bump(declared, target):
            return f"{m.group(1)}{m.group(2)}{target}{m.group(4)}"
        return m.group(0)

    text = pattern.sub(repl, text)
    if text != original:
        path.write_text(text, encoding="utf-8")
        patched += 1
        print(f"Patched {path.as_posix()} → iOS {target}+")

print(
    f"align_spm_ios_platforms: scanned={scanned} patched={patched} floor={target}"
)
PY
