## 1. 骨架与冷态判定

- [x] 1.1 新增 `buildPredictionDemoSkeletonRows`（或等价）：全量无父根 → `SmartPredictionRow`，`nextAt` ∈ (mountNow, mountNow+3h]
- [x] 1.2 用页面 `mountNonce`（或 State 字段）固定各根偏移；秒 tick 只刷新相对文案，不重抽；remount 重抽
- [x] 1.3 在 `SmartPredictionScreen` 接入冷态判定（未登录 / 无 deviceNo / range 空就绪）并切换展示骨架行

## 2. 假留意与 ensure 门闸

- [x] 2.1 冷态渲染固定健康文案的「值得留意」占位（无详情副作用 HTTP）
- [x] 2.2 调整 `UcgHomeShell`（或等价）`ensureLoaded`：仅已登录 + deviceNo + range 真历史非空时拉取
- [x] 2.3 有真历史时恢复既有真留意卡片路径

## 3. 量身定做 Dialog

- [x] 3.1 将 `PredictionRecallOnboardingPanel` 改为 Dialog 呈现；底层保留骨架；禁滑 PageView 行为不变
- [x] 3.2 实现遮罩软关、软关后再弹（头像除外）、收尾永久 `finaleDismissed`
- [x] 3.3 无子根卡片仅展示根自身一钮；会话进度在软关再开时保留
- [x] 3.4 未登录/未绑定不启动量身定做会话

## 4. 头像与清理

- [x] 4.1 预测顶栏头像改为 `/settings`（未登录走既有登录门）；移除引导期强制隐藏三块 chrome 的逻辑（改由 Dialog 遮罩）
- [x] 4.2 冷态骨架卡避免误提交记账（禁用或点后引导登录/绑定）
- [x] 4.3 `openspec validate prediction-demo-skeleton-and-recall-dialog --strict` 通过；手工冒烟冷态/Dialog/有历史路径
