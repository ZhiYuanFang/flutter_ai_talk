## 1. 主页历史 WS 横幅

- [x] 1.1 在 `app/lib/ui/home_screen.dart` 将 `showWsBanner` 收窄为：`loggedIn && !needsDeviceBind && _historyWsPhase == HistoryWsPhase.gaveUp && !refreshInFlight`；删除 `showWsRefreshBanner` / `showWsDisconnectBanner` 分支及对 refresh/disconnected 文案的选择逻辑
- [x] 1.2 横幅展示时固定使用 `kHomeHistoryWsGaveUpMessage`、`HomeHistoryWsBannerVariant.error`、`tapEnabled: true`；确认 `_maybeShowGaveUpSnackbar` 与 gaveUp-only 可见性仍一致
- [x] 1.3 确认 `_ensureHistoryWsForSend` Toast 未改动（发送前未就绪仍提示用户）

## 2. 胖宝诊疗页 WS 横幅

- [x] 2.1 在 `app/lib/ui/pangbao_ai_screen.dart` 应用与主页相同的 gaveUp-only 可见性谓词（含 consent / login / bind 门控）
- [x] 2.2 删除诊疗页 refresh / disconnected 横幅分支；gaveUp Snackbar 与点击重连行为保持不变

## 3. 验证

- [x] 3.1 冷启动进入主页：bootstrap 与 iOS 延迟期间**不得**闪现连接横幅；WS 连上后仍无横幅
- [x] 3.2 断网直至 3-strike gaveUp：主页与诊疗页**必须**展示「连接失败…」横幅 + 一次性 Snackbar；点击横幅可重连成功
- [x] 3.3 token refresh 期间（`isRefreshInFlight`）：**不得**展示任何 WS 连接横幅；refresh 结束后若仍为 gaveUp 则展示横幅
