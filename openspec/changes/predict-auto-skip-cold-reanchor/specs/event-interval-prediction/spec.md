## ADDED Requirements

### Requirement: Client SHALL auto-reanchor once after all-cold without persisting missAnchor

When interval prediction for a non-appointment root follows the existing affinity-weighted median path (not recall-seed-only) and the ordered candidates primary → gePrimary → crossDay all fail the time-of-day histogram density guard, the client MUST perform **at most one** automatic reanchor step before returning: treat the cold primary candidate `nextAt₀ = trueLastAt + interval₀` as the time-of-day affinity anchor to recollect affinity samples and recompute `interval₁`; then set `nextAt₁ = trueLastAt + interval₁` (additive base MUST remain the true latest occurrence tip, MUST NOT be `nextAt₀`). If affinity samples after reanchor are insufficient to form `interval₁`, the client MUST keep `nextAt₀` with time-of-day low-confidence. If `nextAt₁` passes the density guard, the client MUST return `nextAt₁` without low-confidence. If `nextAt₁` still fails the guard, the client MUST return `nextAt₁` with time-of-day low-confidence and MUST NOT perform a second automatic reanchor. The client MUST NOT persist a local missAnchor (or equivalent) for this step. When the path is recall-seed-only (`usedSeed`), the client MUST NOT perform this automatic reanchor; seed-cold behavior remains soft-retain of the seed candidate.

非预约根在非种子路径上按既有亲和中位，且 primary→gePrimary→crossDay 皆未过钟点密度护栏时，客户端 MUST 在返回前做**至多一次**自动换锚：以冷主候选 `nextAt₀ = 真 lastAt + interval₀` 为钟点亲和锚重采样本得 `interval₁`，再令 `nextAt₁ = 真 lastAt + interval₁`（加法基 MUST 仍为真 tip，MUST NOT 为 `nextAt₀`）。换锚后样本不足无法得 `interval₁` 时 MUST 保留 `nextAt₀` 并标钟点把握不足。`nextAt₁` 过护栏 MUST 返回且不标不足；仍不过 MUST 返回 `nextAt₁` 并标不足，且 MUST NOT 再自动跳第二次。MUST NOT 为本步持久化本机 missAnchor。纯回忆种子路径 MUST NOT 自动换锚；种子冷仍软留种子候选。

#### Scenario: 皆冷后一次换锚且落点从真 tip 加

- **WHEN** 非种子路径 primary→gePrimary→crossDay 皆冷，且以 `nextAt₀` 换锚后可得 `interval₁`
- **THEN** 候选 `nextAt₁` MUST 等于真最新发生 tip + `interval₁`
- **AND** MUST NOT 等于 `nextAt₀ + interval₁`（除非与 tip+`interval₁` 数值巧合）

#### Scenario: 换锚后热则采用

- **WHEN** `nextAt₁` 通过密度护栏
- **THEN** 返回预测 MUST 使用 `nextAt₁`
- **AND** MUST NOT 标记钟点把握不足

#### Scenario: 换锚后仍冷则软留且不再跳

- **WHEN** `nextAt₁` 仍未通过密度护栏
- **THEN** 返回预测 MUST 使用 `nextAt₁`
- **AND** MUST 标记钟点把握不足
- **AND** MUST NOT 再进行第二次自动换锚

#### Scenario: 种子路径不自动跳

- **WHEN** 预测走回忆种子间隔（亲和样本不足）且种子候选落冷
- **THEN** MUST NOT 执行自动换锚
- **AND** MUST 软留种子候选（既有种子软标行为）

## REMOVED Requirements

### Requirement: Client SHALL re-predict from a persisted missAnchor after overdue skip

**Reason**: 手工本机 missAnchor 无法多端同步；改由皆冷后一次算法换锚替代。  
**Migration**: 删除 missAnchor 持久化与 API；实现本文件 ADDED 的自动换锚 Requirement。
