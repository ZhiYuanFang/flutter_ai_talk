## Context

服务端流式思考用 `\r` 划分阶段；横屏 `VoiceChatThinkingDelta` 与陪伴 `thinking_delta` 当前均为 `prev + delta`。产品要求：仅适配这两处；分隔符为 `\r`（非单独 `\n`、非必须 `\r\n`）。

## Goals / Non-Goals

**Goals:**

- 共享 `applyThinkingStageDelta(previous, delta) → String`。
- 横屏与陪伴统一走该函数更新展示中的思考文案。

**Non-Goals:**

- 不删首页 Tip / 语音球死代码。
- 不改 Go、不改 tip/home `sendCommand`。
- 不改答语弹幕「播完再清」等既有规则。

## Decisions

1. **分隔符 = `\r`**  
   扫描 `previous +` 逐字符处理 `delta`：遇 `\r` 则 `cur = ''`；其它字符追加。单独 `\n` 视为普通字符。  
   **备选**：`\n` / `\r\n`——已否决。

2. **`\r\n` 兼容**  
   若 `\r` 后紧跟 `\n`，清屏后 **跳过该 `\n`**，避免新阶段以空行开头。

3. **单帧多段**  
   同一 `delta` 含多个 `\r` 时，最终只展示最后一段（同步处理，中间段可能不可见）——可接受。

4. **共享模块位置**  
   `app/lib/util/thinking_stage_delta.dart`（纯函数，无 Flutter 依赖更佳，便于两处引用）。

5. **陪伴**  
   仅改 `thinking_delta` 累加路径；`answer_done` 若下发整段 `thinking` 快照，不在此强制再分段（服务端快照语义另议；本变更以增量路径为准）。

## Risks / Trade-offs

- **[Risk] 服务端仍发 `\n` 分段** → 不会清屏；需与后端约定 `\r`。  
- **[Trade-off] 阶段切换瞬间弹幕可能空一拍** → 符合「清空再填」。  
- **[Risk] 历史已拼长文的会话** → 仅影响新增量；无迁移。

## Migration Plan

1. 合入工具 + 两处调用。  
2. 真机：横屏与陪伴观察阶段性短句。  
3. 回滚：恢复 `+` 拼接。

## Open Questions

（无）分隔符、范围已确认。
