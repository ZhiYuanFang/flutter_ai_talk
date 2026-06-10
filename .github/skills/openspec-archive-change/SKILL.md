---
name: openspec-archive-change
description: 将 OpenSpec change delta 收进指定版本基线（不创建 archive 目录）。Use when the user wants to finalize specs into a version baseline like v2.0.0.
license: MIT
compatibility: Requires openspec CLI and scripts/sync_specs_to_version.py.
metadata:
  author: openspec
  version: "2.0"
  generatedBy: project-custom
---

将 change delta 合并进版本基线（如 `openspec/specs/v2.0.0.md`），**不**使用 `openspec/changes/archive/`。

**Input**: 目标版本名（必填），如 `v2.0.0`。用户只给版本名时直接执行。

**Steps**

1. 解析目标版本（`vX.Y.Z`）
2. 检查起始基线（默认最新 `v*.md`）
3. （可选）警告 in-progress change
4. `python scripts/sync_specs_to_version.py <version> [--base ...] [--remove-changes]`
5. 输出摘要

**Guardrails**: 不做 archive 目录；默认保留 changes；删除需用户明确要求
