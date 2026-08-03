## Context

`session_sync` 非空时 `_applySessionSync` 以服务端 Q&A 重建列表，仅本地 tip/漏网轮次置顶。产品冻结：**展示仅为前端，忽略 session_sync**。

## Goals / Non-Goals

**Goals:**

- `session_sync` 不改 `_items`（忽略合并）。
- 打开陪伴仍 hydrate 本地 store；发送/流式/tip/清理逻辑不变。
- Spec 明确废止「服务端 turns 权威展示」。

**Non-Goals:**

- 不改后端是否推送 `session_sync`。
- 不关掉 Clinic WS 或实时问答。
- 不做多端云同步替代方案。

## Decisions

### 1. 忽略方式

在 `_onFrame` 的 `session_sync` 分支：打日志后 `return`，**不**调用 `_applySessionSync`。  
`_applySessionSync` 可删或保留未引用（优先删除调用；死代码可同 PR 删以免误用）。

### 2. 列表生命周期

```
进入 → hydrate（_items 空时）
发送 / WS 流式 → 追加/更新
tip 注入 → 追加
清理 → clear store + _items
```

不再出现 sync 截断 divider（除非别处仍插入；本变更不再因 sync 插入）。

### 3. 与旧 spec

- v2.0.3 / smart-companion 的 session_sync merge、空 sync 不 wipe、截断 divider：**展示义务取消**；本 change ADDED「MUST NOT apply session_sync to UI」。

## Risks / Trade-offs

- [换机无史] → 产品接受。  
- [后端仍推 sync] → 忽略即可，带宽可忽略。  
- [误删实时帧处理] → 仅动 session_sync 分支。

## Migration Plan

1. 忽略 session_sync 展示。  
2. 手工：重连后列表不被服务端重排；本地 tip/时间仍在。  
3. 清记录仍只清本地。

## Open Questions

- 无。
