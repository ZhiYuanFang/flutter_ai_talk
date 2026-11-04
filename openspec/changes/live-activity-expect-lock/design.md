## Context

锁屏 Timing / Imminent 已是双层布局。Go twin `live-activity-expect-lock-go` 已落地：Imminent ContentState 透传 expect* 且 title 为基句；Timing 经 active-eta update / history update 保留 `expectEndAt`。本仓 Extension 尚未解码与展示；预测右槽若仍用与 Timing 相同的 `.title` 大字，短句「预计1时30分钟」易压过事件名。

## Goals / Non-Goals

**Goals:**

- Timing：标题下可选「预计 HH:mm 结束」。
- Imminent：右侧短版 duration/amount；右槽字号相对既有 trailing `.title` **−5pt**。
- 解码 Go 已推结构化字段；旧推送缺字段兜底。
- 文档对齐 `LIVE_ACTIVITY.md`。

**Non-Goals:**

- Go fanout（twin 已完成；不新开 / 不补 Go 提案）。
- Dynamic Island expect。
- App 内预测卡文案（锁屏故意更短）。
- 本地 `Activity.request`。
- 改 Timing 右槽已计时字号。

## Decisions

1. **与 Go 对齐（不再另提 Go）**  
   字段契约以 twin 为准：Timing `expectEndAt`；Imminent `expectKind` / `expectDurationSec` / `expectAmount` / `expectUnit`。title 由 Go 保证为基句；Swift 原样展示，不二次拼接预计后缀。

2. **短版拼装**  
   - Timing：`预计 HH:mm 结束`；超时不追加；`expectEndAt≤0` → 不画。  
   - duration：`预计{h}时{m}分钟` / `预计{h}时` / `预计{m}分钟`；`sec<60` → 不画。  
   - amount：`预计{N}{unit}`；≤0 不画；不拼 leaf。

3. **布局与字号**  
   `LockScreenTwoTier`：标题列主标题 + 可选副行；trailing 可注入。  
   Timing trailing：保持 `.title`（或等价）已计时。  
   Imminent trailing：在同一 trailing 基准上 **字号 −5pt**（例如基准为 UIKit/SwiftUI `.title` 的 pointSize，则用 `pointSize - 5` 的 semibold）；仅作用于预测右槽 expect 文案，不影响上层「胖宝」与事件名。

4. **Island**  
   MUST NOT 改 Island expect/时间槽。

5. **兼容**  
   `decodeIfPresent`；Attributes 不强制扩 expect。

## Risks / Trade-offs

- [Go 未发字段的旧构建] → 静默无字。  
- [−5pt 在动态 Type 下] → 相对当前 trailing `.title` 减固定 5pt，不跟内容缩放二次加减。  
- [短文案与 App 不一致] → 已接受。

## Migration Plan

1. 发本客户端；与已上线/待发 Go twin 联调。  
2. 回滚：忽略 ContentState 新键 / 恢复右槽 `.title`。

## Open Questions

- 无。**判定：不补充新 Go 提案**（twin 已完成且字段足够）。
