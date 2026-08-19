## REMOVED Requirements

### Requirement: Collapsed dock shows current mode as edge-flush semicircle

**Reason**: 喂养页已不再展示输入模式切换球（见 `feeding-buttons-only`）；贴边半圆球能力改由预测竖屏语音球（`prediction-portrait-voice-dock`）承接，不再表示 voice/buttons/text 模式图标。

**Migration**: 竖屏预测使用 `EdgeDockShell` + 麦克风图标；勿再在喂养页渲染 `HomeInputModeDock`。

### Requirement: Dock is draggable across the home body and snaps to four edges

**Reason**: 拖动吸附行为改由预测竖屏语音球规格约束；喂养页无模式 dock。

**Migration**: 见 `prediction-portrait-voice-dock` 拖动与吸附 Requirement。

### Requirement: Dock position is persisted across sessions

**Reason**: 位置持久化 API（原 `HomeInputDockStore`）转交预测竖屏语音球；语义不再是「首页输入模式 dock」。

**Migration**: 使用同一 Store（可更名）按 `prediction-portrait-voice-dock` 持久化规则；旧喂养存档不得作为预测球默认。

### Requirement: Dock integrates with existing input mode rules

**Reason**: 预测语音球不轮转 `HomeInputChannel`；喂养页锁定按钮模式且无 dock。

**Migration**: 通道轮转仅保留在仍需要的入口（如陪伴）；预测球只触发监听业务回调。

## ADDED Requirements

### Requirement: Home input mode dock MUST remain absent on feeding; store serves prediction voice dock

The feeding `HomeScreen` MUST NOT render `HomeInputModeDock` for voice/text/buttons switching. The client MUST treat `HomeInputDockStore` (or renamed equivalent) as the persistence backend for the **portrait prediction voice edge dock**, not as a feeding input-mode switcher position store.

喂养页 **不得** 渲染 `HomeInputModeDock` 做语音/文字/按钮切换。客户端 **必须** 将 `HomeInputDockStore`（或更名等价物）作为**竖屏预测语音贴边球**的位置持久化后端，**不得** 再将其语义当作喂养输入模式切换球。

#### Scenario: 喂养页仍无模式球

- **WHEN** 用户打开喂养页
- **THEN** UI MUST NOT 展示输入模式切换 EdgeDock 球

#### Scenario: Store 服务预测球

- **WHEN** 用户在竖屏预测拖动语音球并松手
- **THEN** 客户端 MUST 经原 HomeInputDockStore 语义 API 写入该球位置（供下次竖屏预测恢复）
