---
name: /opsx-archive
id: opsx-archive
category: Workflow
description: 将 OpenSpec change delta 收进指定版本基线（不创建 archive 目录）
---

将 `openspec/changes/` 下各 change 的 delta spec 合并进目标版本基线文件（如 `openspec/specs/v2.0.0.md`）。**不**移动 change 到 `openspec/changes/archive/`，**不**创建 dated archive 目录。

**Input**：目标版本名（必填），例如 `/opsx-archive v2.0.0` 或 `/opsx-archive 2.0.0`。若用户只给版本名，**直接执行**，无需再确认 change 选择或 archive 路径。

可选参数（用户显式提及时才用）：
- `--base v1.0.1`：指定起始基线；省略则用 `openspec/specs/v*.md` 中最新一份
- `--keep-changes`：合并成功后**保留** `openspec/changes/*`；**默认行为是删除**（见 `openspec/project.md`「OpenSpec 归档约定」）

**Steps**

1. **解析目标版本**

   从用户输入提取版本标签，规范为 `vX.Y.Z`（无 `v` 前缀则补上）。

2. **检查起始基线**

   - 默认：`openspec/specs/` 下按文件名排序最新的 `v*.md`
   - 用户指定 `--base` 时用该文件
   - 若目标版本文件已存在，提示将覆盖并继续（除非用户说取消）

3. **（可选）检查 change 与任务状态**

   运行 `openspec list --json`，统计 `openspec/changes/` 下含 `specs/` 的 change 数量；对 `status != complete` 的 change 列出警告（名称、completedTasks/totalTasks），**不阻塞**合并，除非用户明确要求只合并 complete 的 change。

4. **执行合并**

   ```bash
   python scripts/sync_specs_to_version.py <version> [--base vX.Y.Z] [--remove-changes]
   ```

   **默认必须加 `--remove-changes`**（除非用户显式 `--keep-changes` 或要求保留）。

   脚本行为：
   - 从基线解析 capability
   - 按 change 目录 mtime 顺序应用全部 delta（ADDED / MODIFIED / REMOVED）
   - 写出 `openspec/specs/<version>.md`
   - 删除 `openspec/changes/*`（跳过 `archive/`）

5. **显示摘要**

   输出：目标版本、起始基线、capability 数、应用的 delta 条数、输出路径、删除的 change 目录数量（**Changes removed: yes/no**）；并更新 **`openspec/project.md`** 基线版本号。

**Output On Success（默认）**

```
## Spec 收进完成

**Version:** v2.0.0
**Base:** v1.0.1.md
**Output:** openspec/specs/v2.0.0.md
**Capabilities:** 154
**Deltas applied:** 128
**Changes removed:** 32 个 change 目录已删除（无 archive/）

未创建 archive 目录。
```

**Output On Success（含 --keep-changes）**

```
**Changes removed:** no（保留 openspec/changes/）
```

**Guardrails**

- 本命令**只做版本基线合并**，不做 `openspec/changes/archive/` 归档
- 用户只给版本名时**自动执行**，不要 AskUserQuestion 选 change
- **默认删除** change 目录；保留须用户显式 `--keep-changes`
- 合并后提醒：涉及行为变更的 PR/评审应引用 `openspec/specs/<version>.md` 中对应 capability
