## MODIFIED Requirements

### Requirement: App SHALL fetch notify banner from NOTIFY_BASE_URL on home entry

客户端 MUST 通过 `--dart-define=NOTIFY_BASE_URL` 配置独立基址（`AppEnv.notifyBaseUrl`），与 `API_BASE_URL` 分离。若 `NOTIFY_BASE_URL` 为空，MUST 回退 legacy `--dart-define=STATUS_BASE_URL`（默认 `https://status.pangbao.cuplay.top`）。进入 `/home` 且 **`UcgHomeShell` 挂载后** MUST 在 postFrameCallback（或等价首帧回调）发起 `GET {notifyBaseUrl}/app/api/status/banner`（无鉴权），**未登录用户 MUST 同样执行**。该拉取与弹窗 MUST 由主壳启动编排触发，MUST NOT 依赖喂养页 `HomeScreen` mount。拉取与展示 MUST **先于**版本更新弹窗，且若展示了 notify 弹窗则 MUST **await 关闭后** 再进入版本步骤。App lifecycle resume 与主壳已挂载期间的登录成功 MUST NOT 再次自动拉取/弹 notify。

#### Scenario: logged out user sees maintenance

- **WHEN** 用户未登录且 notify 服务返回 `active=true`
- **THEN** 主页 MUST 展示维护弹窗

#### Scenario: legacy STATUS_BASE_URL still works

- **WHEN** 构建仅传入 `STATUS_BASE_URL` 且未传 `NOTIFY_BASE_URL`
- **THEN** `AppEnv.notifyBaseUrl` MUST 使用该 legacy 值

#### Scenario: 预测页着陆也拉 notify

- **WHEN** 用户进入 `/home` 且当前页为智能预测（喂养页可能尚未构建）
- **THEN** 客户端 MUST 仍发起 notify banner 拉取（并在 active 时弹窗）

#### Scenario: resume 不自动弹 notify

- **WHEN** 应用 resume 且主壳仍挂载
- **THEN** 客户端 MUST NOT 仅因 resume 再次自动展示 notify 弹窗

#### Scenario: 登录中途不自动弹 notify

- **WHEN** 主壳已挂载期间用户登录成功
- **THEN** 客户端 MUST NOT 因此再次自动展示 notify 弹窗
