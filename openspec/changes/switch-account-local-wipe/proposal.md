## Why

切换账号/注销时文案承诺清除宝宝与喂养本地缓存，但当前 mainly 清 session、`deviceNo` 与历史磁盘；进程内历史内存、宝宝 prefs 画像与头像副本可能残留，存在串账号展示风险。需要一份可复用的本地擦除路径，保证切号后冷数据不带入下一会话。

## What Changes

- 抽取统一的「账号本地擦除」流程（切换账号与注销共用）。
- 擦除范围覆盖：会话与登录渠道、`deviceNo`、喂养历史磁盘 + 内存（含 `HomeHistoryMemoryCache` / `homeHistory` 状态）、宝宝 prefs 画像、宝宝头像本地副本，并 invalidate 依赖的展示 Provider。
- 保持已落地的宿主 `hostContext` / `ProviderContainer` 跳转登录（不依赖已 dispose 的 Sheet `ref`）。
- 不改变 `/settings` 游客可访问的路由策略。

## Capabilities

### New Capabilities

- `account-local-wipe`：切换账号与注销时客户端本地宝宝/喂养/会话相关缓存的擦除契约。

### Modified Capabilities

- （无；基线 `username-account-management` 未规定完整本地擦除清单，以新 capability 承接。）

## Impact

- `account_management_sheet.dart`（切换账号 / 注销）
- 可能新增小 helper（如 `bootstrap/` 或 `session/` 下 wipe 函数）
- 触及：`HomeHistoryMemoryCache`、`homeHistoryProvider`、`feedRepository.clearCache`、`deviceNoNotifier`、宝宝 prefs / `BabyAvatarLocalStore`、`settingsBabyProvider`（及头像相关 provider）
- 无新后端 API
