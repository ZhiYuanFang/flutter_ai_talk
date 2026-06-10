---
description: 将 OpenSpec change delta 收进指定版本基线（不创建 archive 目录）
---

将 `openspec/changes/` 下各 change 的 delta spec 合并进目标版本基线文件（如 `openspec/specs/v2.0.0.md`）。**不**移动 change 到 `openspec/changes/archive/`，**不**创建 dated archive 目录。

**Input**：目标版本名（必填），例如 `/opsx-archive v2.0.0` 或 `/opsx-archive 2.0.0`。若用户只给版本名，**直接执行**，无需再确认 change 选择或 archive 路径。

可选参数（用户显式提及时才用）：
- `--base v1.0.1`：指定起始基线；省略则用 `openspec/specs/v*.md` 中最新一份
- `--remove-changes`：合并成功后删除 `openspec/changes/*`（仍**不**写入 archive/）；默认**保留** change 目录

**Steps**

1. **解析目标版本** — 规范为 `vX.Y.Z`
2. **检查起始基线** — 默认最新 `v*.md`；目标文件已存在则覆盖
3. **（可选）警告 in-progress change** — `openspec list --json`，不阻塞
4. **执行** — `python scripts/sync_specs_to_version.py <version> [--base ...] [--remove-changes]`
5. **摘要** — 版本、基线、capability/delta 数、输出路径

**Guardrails**

- 只做版本基线合并，不做 archive 目录归档
- 用户只给版本名时自动执行
- 默认保留 change 目录
