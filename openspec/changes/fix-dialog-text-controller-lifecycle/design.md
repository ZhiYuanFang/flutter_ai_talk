## Context

邀请码兑换走 `showGlassDialog` + 外层 `TextEditingController`：`await` 返回后立即 `dispose`，与 dialog route 退场动画重叠，触发 `TextEditingController was used after being disposed`。仓库已有正确范例 `_GlassTextConfirmDialogBody`（State 持有 controller）。需修现网点，并把约定写入 `project.md`，避免后续弹框再踩。

## Goals / Non-Goals

**Goals:**

- 邀请码弹窗关闭（兑换/取消/点遮罩）过程中不再因 controller 过早 dispose 断言。
- 审计并消除同类「外层创建 + await 后 dispose」反模式。
- `project.md` 明确：弹框内文本输入的 controller / FocusNode 归属 State（或等价 route 卸载后再 dispose）。

**Non-Goals:**

- 不改兑换 HTTP、Toast 文案、开通中心其它 CTA。
- 不强制把全仓所有页面级 TextField（非 dialog）迁成新基类。
- 不新建 `**/test/**`。

## Decisions

### D1：优先 StatefulWidget 包住输入（方案 A）

邀请码内容抽成私有 StatefulWidget（或复用/扩展 glass 文本确认体），在 `State.dispose` 释放 controller。`Navigator.pop` 前可读出 `text` 经 `pop(result)` 带回，或由 body 回调；外层 **禁止** 在 `showGlassDialog` Future 完成后立刻 `dispose`。

备选 B（postFrameCallback dispose）可修单点，但易忘、难审计；规范以 A 为准。

### D2：工程约定落点 = `openspec/project.md`

新增短节「弹框 TextEditingController / FocusNode」：

- MUST：由 dialog 子树 `State` 创建并在该 State `dispose` 释放；或仅在 route 完全卸载后释放。
- MUST NOT：在 `await showDialog` / `showGlassDialog` / `showModalBottomSheet` 返回后、退场动画仍可能 rebuild 输入控件时立刻 `dispose`。
- 参考：`_GlassTextConfirmDialogBody`。

AI / 人工写新弹框时对照 AGENTS → project.md。

### D3：审计范围

`app/lib/**` 搜索「函数内 `TextEditingController()` + dialog/sheet await 后 dispose」。当前已知热点：`feature_unlock_hub_screen._openInviteDialog`。页面级 State 字段持有的 controller 不在本变更强制改写范围。

### D4：结果回传

兑换成功路径仍：读码 → `redeemInviteCode` → Toast → `onChanged`。弹窗本身可 `pop(String? code)` 或 `pop(bool)` + 内部已在 pop 前取出文本；实现择一，保持外层语义不变。

## Risks / Trade-offs

- [漏审同类点] → tasks 要求 grep 清单勾选。
- [仅写 project.md 无人读] → AGENTS 已指向 project.md；本 change tasks 含文档条目。
- [过度抽象公共组件] → 邀请码可本地私有 widget；不必新建通用库除非审计发现 ≥3 处重复。

## Migration Plan

- 纯客户端热更新即可。回滚：恢复外层 controller（不推荐）。

## Open Questions

- 无。
