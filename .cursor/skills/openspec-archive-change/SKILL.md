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

1. **解析目标版本**

   规范为 `vX.Y.Z`（无 `v` 则补上）。

2. **检查起始基线**

   默认取 `openspec/specs/v*.md` 最新；用户可指定 `--base`。

3. **（可选）警告未 complete 的 change**

   `openspec list --json` 列出 in-progress change，不阻塞除非用户要求仅合并 complete。

4. **执行合并**

   ```bash
   python scripts/sync_specs_to_version.py <version> [--base vX.Y.Z] [--remove-changes]
   ```

5. **摘要**

   报告版本、基线、capability 数、delta 数、是否删除 change 目录。

**Guardrails**

- 不做 dated archive 目录移动
- 默认保留 `openspec/changes/`
- 删除 change 目录需用户明确要求
