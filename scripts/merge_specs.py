#!/usr/bin/env python3
"""Merge all openspec/specs/**/spec.md into a single baseline file.

Prefer scripts/sync_specs_to_version.py for absorbing change deltas into vX.Y.Z.
"""
from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Merge per-capability spec.md files into one baseline.")
    parser.add_argument("version", nargs="?", default="v1.0.1", help="Target version label, e.g. v2.0.0")
    args = parser.parse_args()
    version = args.version if args.version.startswith("v") else f"v{args.version}"

    root = Path(__file__).resolve().parents[1] / "openspec" / "specs"
    out = root / f"{version}.md"
    specs = sorted({p.resolve() for p in root.rglob("spec.md") if p.name == "spec.md"})

    lines: list[str] = [
        f"# 胖宝 OpenSpec 基线 {version}",
        "",
        f"> 由 `openspec/specs/**/spec.md` 共 **{len(specs)}** 个 capability 合并生成。",
        f"> 生成日期：{date.today().isoformat()}",
        "",
        "## 目录",
        "",
    ]

    for p in specs:
        cap = p.parent.name
        lines.append(f"- [{cap}](#capability-{cap})")

    lines.extend(["", "---", ""])

    for p in specs:
        cap = p.parent.name
        content = p.read_text(encoding="utf-8").strip()
        rel = p.relative_to(root.parent.parent).as_posix()
        lines.extend(
            [
                f'<a id="capability-{cap}"></a>',
                "",
                f"# Capability: {cap}",
                "",
                f"<!-- source: {rel} -->",
                "",
                content,
                "",
                "---",
                "",
            ]
        )

    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out} ({out.stat().st_size:,} bytes, {len(specs)} capabilities)")


if __name__ == "__main__":
    main()
