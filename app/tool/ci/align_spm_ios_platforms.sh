#!/usr/bin/env bash
# 抬高依赖 FlutterFramework 的消费方 Package.swift 的 .iOS("…")，消除
# Target Integrity（例：photo_manager .iOS("9.0")→钳成 12 vs FlutterFramework 13）。
#
# 扫描范围（CI 日志曾 scanned=2 漏掉插件）：
# 1) ios/Flutter/ephemeral/Packages（含 .packages，跟随 symlink）
# 2) .dart_tool/package_config.json 指向的各 package 根下 darwin/ios Package.swift
# 3) $PUB_CACHE 中含 FlutterFramework 依赖的 Package.swift
#
# 规则：
# - FlutterFramework：仅保证 ≥13.0，不抬到主 App 17
# - 其它消费方：低于 IOS_DEPLOYMENT_TARGET（默认 17）抬到该基线
# - 结束后消费方仍 < 基线 → exit 1
set -euo pipefail

cd "$(dirname "$0")/../.."

target="${IOS_DEPLOYMENT_TARGET:-17.0}"
packages_root="ios/Flutter/ephemeral/Packages"
ff_floor="13.0"
pub_cache="${PUB_CACHE:-${PUB_CACHE_DIR:-}}"
if [[ -z "$pub_cache" ]]; then
  if [[ -d "${HOME}/.pub-cache" ]]; then
    pub_cache="${HOME}/.pub-cache"
  elif [[ -d "${LOCALAPPDATA:-}/Pub/Cache" ]]; then
    pub_cache="${LOCALAPPDATA}/Pub/Cache"
  fi
fi

if [[ ! -d "$packages_root" ]]; then
  echo "align_spm_ios_platforms: 跳过（无 $packages_root，请先 flutter build ios --config-only）"
  exit 0
fi

# 诊断：.packages 里有什么（photo_manager 常在 archive 时才以 @ local 出现）
if [[ -d "$packages_root/.packages" ]]; then
  echo "align_spm_ios_platforms: .packages entries:"
  ls -la "$packages_root/.packages" | sed 's/^/  /' || true
fi

TARGET="$target" FF_FLOOR="$ff_floor" PACKAGES_ROOT="$packages_root" PUB_CACHE="${pub_cache:-}" python3 <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

target = (os.environ.get("TARGET") or "17.0").strip() or "17.0"
ff_floor = (os.environ.get("FF_FLOOR") or "13.0").strip() or "13.0"
root = Path(os.environ["PACKAGES_ROOT"])
pub_cache = Path(os.environ["PUB_CACHE"]) if os.environ.get("PUB_CACHE") else None

pattern = re.compile(r"""(\.iOS\(\s*)(['"])([^'"]+)(\2\s*\))""")
ff_dep = re.compile(r"FlutterFramework")


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
    try:
        return path.resolve().parent.name == "FlutterFramework"
    except OSError:
        return path.parent.name == "FlutterFramework"


def add_package_swift(out: set[Path], base: Path) -> None:
    if not base.exists():
        return
    # 直接 Package.swift
    for name in ("Package.swift",):
        p = base / name
        if p.is_file():
            out.add(p.resolve() if p.exists() else p)
    # darwin/<pkg>/Package.swift、ios/<pkg>/Package.swift 等
    for sub in ("darwin", "ios", "macos"):
        d = base / sub
        if not d.is_dir():
            continue
        for p in d.rglob("Package.swift"):
            try:
                out.add(p.resolve())
            except OSError:
                out.add(p)


def collect_candidates() -> list[Path]:
    found: set[Path] = set()

    # 1) ephemeral（跟随 symlink：resolve）
    if root.is_dir():
        for p in root.rglob("Package.swift"):
            try:
                found.add(p.resolve())
            except OSError:
                found.add(p)
        packages_dot = root / ".packages"
        if packages_dot.is_dir():
            for child in packages_dot.iterdir():
                add_package_swift(found, child)

    # 2) package_config.json → 各依赖根
    pkg_config = Path(".dart_tool/package_config.json")
    if pkg_config.is_file():
        data = json.loads(pkg_config.read_text(encoding="utf-8"))
        for pkg in data.get("packages", []):
            root_uri = pkg.get("rootUri") or ""
            if not root_uri:
                continue
            # file:///... 或 ../.pub-cache/... 或相对
            if root_uri.startswith("file:"):
                # file:///C:/... or file:///Users/...
                path_str = root_uri[5:]
                if path_str.startswith("///"):
                    path_str = path_str[2:]  # keep one /
                    if re.match(r"^/[A-Za-z]:", path_str):
                        path_str = path_str[1:]  # Windows file:///C:/
                pkg_root = Path(path_str)
            else:
                pkg_root = (pkg_config.parent / root_uri).resolve()
            add_package_swift(found, pkg_root)

    # 3) PUB_CACHE（hosted/git）：含 FlutterFramework 的 Package.swift
    if pub_cache and pub_cache.is_dir():
        for sr_name in ("hosted", "git"):
            sr = pub_cache / sr_name
            if not sr.is_dir():
                continue
            for pattern_glob in ("**/darwin/**/Package.swift", "**/ios/**/Package.swift"):
                for p in sr.glob(pattern_glob):
                    try:
                        text = p.read_text(encoding="utf-8", errors="ignore")
                    except OSError:
                        continue
                    if not ff_dep.search(text):
                        continue
                    try:
                        found.add(p.resolve())
                    except OSError:
                        found.add(p)

    return sorted(found, key=lambda p: str(p))


candidates = collect_candidates()
print(f"align_spm_ios_platforms: candidates={len(candidates)}")

patched = 0
scanned = 0
remaining_low: list[str] = []
# 仅对「含 FlutterFramework」或 ephemeral 内文件强制验收消费方基线
must_check: list[Path] = []

for path in candidates:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"  skip unreadable {path}: {e}")
        continue

    under_ephemeral = False
    try:
        path.resolve().relative_to(root.resolve())
        under_ephemeral = True
    except (ValueError, OSError):
        under_ephemeral = False

    has_ff = bool(ff_dep.search(text)) or is_flutter_framework(path)
    # pub-cache 里无关 Package.swift 已在 collect 时过滤；此处再保险
    if not under_ephemeral and not has_ff and not is_flutter_framework(path):
        continue

    scanned += 1
    original = text
    floor = ff_floor if is_flutter_framework(path) else target
    rel = str(path)

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

    for line in text.splitlines():
        if ".iOS(" in line:
            print(f"  platforms: {rel}: {line.strip()}")

    if under_ephemeral or has_ff:
        must_check.append(path)
        check_floor = ff_floor if is_flutter_framework(path) else target
        for m in pattern.finditer(text):
            if needs_bump(m.group(3), check_floor):
                remaining_low.append(f"{rel} still .iOS(\"{m.group(3)}\") < {check_floor}")

print(
    f"align_spm_ios_platforms: scanned={scanned} patched={patched} "
    f"app_floor={target} ff_floor={ff_floor} must_check={len(must_check)}"
)

if remaining_low:
    print("align_spm_ios_platforms: ERROR residual low platforms:", file=sys.stderr)
    for row in remaining_low:
        print(f"  {row}", file=sys.stderr)
    sys.exit(1)

# 已知凶手：若 pub-cache/ephemeral 仍找不到任何含 photo_manager 且已抬高的声明，给出提示
photo_hits = [p for p in must_check if "photo_manager" in str(p).replace("\\", "/")]
if not photo_hits:
    print(
        "align_spm_ios_platforms: warning: 未找到 photo_manager Package.swift；"
        "若 archive 仍报 photo_manager supports 12，检查 PUB_CACHE 与 package_config"
    )
else:
    print(f"align_spm_ios_platforms: photo_manager paths={len(photo_hits)}")
PY
