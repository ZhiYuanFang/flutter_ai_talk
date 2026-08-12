## ADDED Requirements

### Requirement: 预测页飞入 MUST 在行重排布局后再测锚开播

When the smart prediction page is visible and a history mutation triggers the shared fly animation, the client MUST allow the prediction row list to update and lay out from the new history (including `nextAt` reordering) before locking the fly landing end point and starting the motion toward that point. The client MUST NOT freeze prediction row order for the duration of the fly as the primary strategy for this requirement (feeding-page history freeze MAY remain unchanged). 当智能预测页可见且历史变动触发共享飞入时，客户端 MUST 先让预测行列表按新历史完成更新与布局（含按 `nextAt` 重排），再锁定飞入落点并开播；MUST NOT 以「飞入全程冻结预测行序」作为本需求的主策略（喂养页历史冻结 MAY 保持不变）。

#### Scenario: 加事件导致卡片换位后落点跟新位

- **WHEN** 用户在预测页导致历史 upsert，且对应根事件预测卡因 `nextAt` 变化而换位
- **THEN** 飞入动画的落点 MUST 为重排布局后该卡当前 logo 的全局中心（不得明显落在换位前的旧槽）

#### Scenario: 延迟仅影响开播不推迟落库

- **WHEN** History WS 推送 upsert
- **THEN** 本地历史 MUST 仍立即应用变更
- **AND** 仅预测向飞入的测锚/开播 MUST 发生在随后的布局稳定窗口之后
