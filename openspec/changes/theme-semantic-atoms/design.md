## Context

`AppVisualTokens` 已有 `shell` / `surface` / `recordsCard` / `on*`，`theme-tokens-dark-shell-audit` 又加了 `themeGlassFill` 等 helper。但业务仍混用角色：暗壳 `recordsCard` 故意做成 L≈0.94 浅卡（Feed/历史），Dialog 却用同一 glass fill + `onShell` 白字 → 夜空引导卡不可读。`HistoryEditGlassPanel` 仍写死深色 hex。用户要求 Phase 0–3 一次做完，且**除事件色外**主题色全局原子化。

## Goals / Non-Goals

**Goals:**

- 建立语义原子目录与唯一派生点；业务只选角色。
- Modal/软引导暗壳走暗浮层（B）：`modal*` ≠ `contentCard*`。
- 统一 Dialog/Sheet 容器与预测门禁、召回浮层。
- 高频页面迁入；清扫业务拼色与死 hex；升级 `project.md` 契约。

**Non-Goals:**

- 不改主题预设/定时夜空产品逻辑（仍用既有 schedule）。
- 不强制改事件 `colorHex`、媒体遮罩、SDK 色。
- 不引入 custom_lint / 不新建 `**/test/**`。
- 不要求一次改完所有非 UI 包（如纯 data）；范围 `app/lib/ui/**`、`app/lib/ucg/**` 及 `app/lib/theme/**`。

## Decisions

### D1：原子面 API 形态

提供 `AppColor`（或等价）静态方法 + 扩展 `AppVisualTokens` 字段双轨：  
- Token 字段承载派生结果（可 lerp）。  
- `AppColor.pageBg(context)` 等为业务唯一推荐入口（内部读 tokens / scheme）。  

旧 `themeGlassFill` 等改为**按角色转发**（`contentCard` vs `modal`），禁止业务再传 alpha「旋钮」作为主题算法；若保留可选 alpha，仅限原子内部默认常量。

### D2：角色目录与暗壳派生

| 原子 | 浅壳 | 暗壳 |
|------|------|------|
| `pageBg` | shell | shell |
| `textPrimary` | onShell | onShell |
| `textSecondary` / `textMuted` | onShell×α | 同左（α 在原子内） |
| `surface` / `textOnSurface` | surface / onSurface | 同 |
| `contentCard` / `textOnContentCard` | 近白卡 / 深字 | 可保留偏亮 records 卡 + `onRecordsCard` |
| `modalFill` / `textOnModal` / `modalBorder` | 浅玻璃 + 深字 | **surface(+低 primary) + onShell** |
| `sheetFill` / `textOnSheet` | 默认同 modal（或略深） | 同 |
| `fieldFill` / `fieldBorder` | 浅 inset | surface 叠 primary |
| `primary` / `onPrimary` | ColorScheme | 同 |
| `divider` | surfaceBorder | 同 |
| `barrier` | 黑 α 固定或跟 shell | 同 |

`isDarkShell` **仅**允许出现在 `theme/` 派生与原子实现内。

### D3：统一容器

- 新增或抽出 `AppModalGlassPanel`（名称可调整），填充/边/默认字色绑定 `modal*`。  
- `showGlassDialog` / `showGlassConfirmDialog` 默认挂该 panel；`useLightGlass` 若保留须映射到明确角色或废弃。  
- `_PredictionAuthGateCard`、召回软浮层外壳改用同一 modal 原子（可仍自定义内容布局）。  
- `HistoryEditGlassPanel`：底板/描边/默认字走 `sheet*`/`modal*`；`eventAccent` 仅影响渐变强调，不覆盖正文角色。

### D4：Phase 落地顺序（同一 change 内）

0. Token + `AppColor` + `project.md` 契约；modal 派生按 B。  
1. 统一容器 + 预测门禁/召回 + `showGlassDialog` 路径。  
2. 绑定、UCG Feed/广场、设置、预测页高频 `text*`/`pageBg`/`contentCard*`。  
3. 清扫 `ui`/`ucg` 内拼色 `isDarkShell`、死 hex、误用 glass；`dart analyze`；手工矩阵。

### D5：与 audit change 关系

`theme-tokens-dark-shell-audit` 为前传；本 change 实现时以原子 API 为准替换临时 helper 用法。归档顺序：可先完成并归档本 change，或先归档 audit 再合并基线——实现不依赖未合并 delta 文件存在。

### Alternatives considered

- **仅改引导卡字色为 onRecordsCard**：修单点但不达「全局原子」。否决。  
- **暗壳 contentCard 也改成深色**：破坏 Feed「浅卡」产品习惯。否决；用角色分离。  
- **只扩 helper 不扩 token 字段**：难 lerp、难「一处改处处改」。否决主路径；helper 仅为薄封装。

## Risks / Trade-offs

- [大范围 UI 色漂] → 按 Phase 提交；矩阵必测夜空 Dialog 与 Feed 浅卡是否仍区分。  
- [HistoryEditGlassPanel 字色从固定浅字改为 token] → 深色强调底上须保证 `textOnModal` 仍高对比；事件 accent 渐变保留。  
- [与未归档 audit 冲突] → 以本 change design 为准，apply 时统一改调用点。  
- [全仓清扫漏网] → Phase 3 以 `rg isDarkShell` / 硬编码白底为检查清单，允许注释例外残留。

## Migration Plan

- 纯客户端。回滚：恢复旧 token/组件取色。  
- 旧 helper 可先 `@Deprecated` 转发原子，再删调用。  
- 无服务端/持久化迁移。

## Open Questions

- （无）modal=暗浮层、contentCard=可浅、Phase 0–3 同 change 已由用户确认。`sheet` 与 `modal` 默认同源，若实现中 Sheet 需略深可在原子内微调而不开新角色。
