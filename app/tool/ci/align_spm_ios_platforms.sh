#!/usr/bin/env bash
# 抬高 ephemeral SPM 中「消费方」Package.swift 的 .iOS("…")，消除
# FlutterFramework(产品要求 ≥13) vs consumer platforms 12 的 Target Integrity。
#
# 规则：
# - FlutterFramework：只保证不低于其产品下限 13.0，绝不抬到主 App 15（否则「要求」更高、更易失败）
# - 其它 Package.swift：低于 IOS_DEPLOYMENT_TARGET（默认 15.0）的抬到该基线
# - 结束后若仍有消费方 < 基线 → exit 1
set -euo pipefail

cd "$(dirname "$0")/../.."

target="${IOS_DEPLOYMENT_TARGET:-15.0}"
packages_root="ios/Flutter/ephemeral/Packages"
ff_floor="13.0"

if [[ ! -d "$packages_root" ]]; then
  echo "align_spm_ios_platforms: 跳过（无 $packages_root，请先 flutter build ios --config-only）"
  exit 0
fi

TARGET="$target" FF_FLOOR="$ff_floor" PACKAGES_ROOT="$packages_root" python3 <<'PY'
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

target = (os.environ.get("TARGET") or "15.0").strip() or "15.0"
ff_floor = (os.environ.get("FF_FLOOR") or "13.0").strip() or "13.0"
root = Path(os.environ["PACKAGES_ROOT"])

# .iOS("12.0") / .iOS('12.0')
pattern = re.compile(r"""(\.iOS\(\s*)(['"])([^'"]+)(\2\s*\))""")


def parse_ver(s: str) -> tuple[int, ...]:
    parts: list[int] = []
    for p in s.strip().split("."):
        if not p.isdigit():
            break
        parts.append(int(p))
    return tuple(parts) if parts else (0,)


def needs_bump(declared: str, floor: str) -> bool:
    return parse_ver(declared) < parse_ver(floor)


def is_flutter_framework(path: Path) -> bool:
    # .../.packages/FlutterFramework/Package.swift
    return path.parent.name == "FlutterFramework"


patched = 0
scanned = 0
remaining_low: list[str] = []

for path in sorted(root.rglob("Package.swift")):
    scanned += 1
    text = path.read_text(encoding="utf-8")
    original = text
    floor = ff_floor if is_flutter_framework(path) else target
    rel = path.as_posix()

    def repl(m: re.Match[str], _floor: str = floor) -> str:
        declared = m.group(3)
        if needs_bump(declared, _floor):
            return f"{m.group(1)}{m.group(2)}{_floor}{m.group(4)}"
        return m.group(0)

    text = pattern.sub(repl, text)
    if text != original:
        path.write_text(text, encoding="utf-8")
        patched += 1
        print(f"Patched {rel} → iOS {floor}+")

    # 诊断：列出 platforms 行
    for line in text.splitlines():
        if ".iOS(" in line:
            print(f"  platforms: {rel}: {line.strip()}")

    # 消费方不得仍低于主 App 基线；FlutterFramework 不得低于 13
    check_floor = ff_floor if is_flutter_framework(path) else target
    for m in pattern.finditer(text):
        if needs_bump(m.group(3), check_floor):
            remaining_low.append(f"{rel} still .iOS(\"{m.group(3)}\") < {check_floor}")

print(f"align_spm_ios_platforms: scanned={scanned} patched={patched} app_floor={target} ff_floor={ff_floor}")

if remaining_low:
    print("align_spm_ios_platforms: ERROR residual low platforms:", file=sys.stderr)
    for row in remaining_low:
        print(f"  {row}", file=sys.stderr)
    sys.exit(1)
PY
