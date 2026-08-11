## ADDED Requirements

### Requirement: 预测页横屏 MUST 沉浸隐藏系统栏并保持亮屏

When the smart prediction page is visible and the device orientation is landscape, the App client MUST enter an immersive system UI mode that hides the status bar (sticky immersive equivalent to `SystemUiMode.immersiveSticky` or documented equivalent) and MUST maximize the prediction content by not applying top/bottom `SafeArea` insets that reserve status-bar space. While that condition holds, the client MUST keep the screen awake (wakelock) so the system MUST NOT auto-lock/sleep solely due to idle timeout. When orientation returns to portrait, or the smart prediction page is no longer the visible home pager page, the client MUST restore normal system UI (e.g. edge-to-edge) and MUST release the wakelock. Web MAY no-op these platform APIs. Feeding and UCG pages are out of scope for this requirement.

智能预测页可见且设备为横屏时，App 客户端 **必须** 进入隐藏状态栏的沉浸式系统 UI（sticky 沉浸，等价于 `SystemUiMode.immersiveSticky` 或已文档化等价物），并 **必须** 通过取消顶/底 `SafeArea` 状态栏占位以最大化预测内容。该条件成立期间客户端 **必须** 保持屏幕常亮（wakelock），使系统 **不得** 仅因空闲超时自动熄屏锁屏。当恢复竖屏，或智能预测页不再是主页 PageView 的当前可见页时，客户端 **必须** 恢复常规系统 UI（如 edge-to-edge）并 **必须** 释放 wakelock。Web MAY 对这些平台 API 空操作。喂养页与 UCG 页不在本需求范围。

#### Scenario: 预测页横屏进入沉浸与常亮

- **WHEN** 用户在智能预测页且设备为横屏
- **THEN** 客户端 MUST 隐藏系统状态栏（沉浸 sticky）
- **AND** 预测内容 MUST NOT 被状态栏 SafeArea 顶/底占位压缩
- **AND** 客户端 MUST 启用屏幕常亮

#### Scenario: 回竖屏恢复

- **WHEN** 用户仍在智能预测页但设备转回竖屏
- **THEN** 客户端 MUST 恢复常规系统 UI
- **AND** MUST 关闭屏幕常亮

#### Scenario: 滑离预测页恢复

- **WHEN** 用户处于预测页横屏沉浸中，滑到喂养或广场页
- **THEN** 客户端 MUST 恢复常规系统 UI
- **AND** MUST 关闭屏幕常亮

#### Scenario: 喂养横屏不受影响

- **WHEN** 用户在喂养页且设备为横屏
- **THEN** 本需求 MUST NOT 要求喂养页启用预测页的沉浸与常亮策略
