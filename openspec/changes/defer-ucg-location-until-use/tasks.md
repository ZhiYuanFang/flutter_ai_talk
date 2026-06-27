## 1. UCG 定位同意模块（`ucg-location-consent`）

- [x] 1.1 在 `ucg_location.dart`（或新文件）实现 `ensureUcgLocationForDistance(BuildContext)`：Web 返回 null；已授权直接取坐标；本进程已拒绝 / deniedForever 不 request
- [x] 1.2 实现 in-app 用途说明 Dialog（文案：用于展示动态与你的距离；拒绝后仍可使用）及 session 级 `deniedThisSession` 状态（Riverpod `StateProvider` 或等价）
- [x] 1.3 实现 `UcgLocationSettingsHint` 组件：session 拒绝或无坐标时在广场展示「去设置」，点击 `openAppSettings`
- [x] 1.4 将现有 `tryGetCurrentCoords` 调用点迁移为 `ensureUcgLocationForDistance`（保留无 UI 的坐标读取 helper 供详情 provider 在已授权时使用）

## 2. 延迟挂载 UCG（`ucg-home-entry`）

- [x] 2.1 `UcgHomeShell` 改为 `PageView.builder`（或等价）+ `_ucgEverMounted`：冷启动不 build `UcgShell`
- [x] 2.2 首次进入 page 1（横滑或「进入广场」）时置 `_ucgEverMounted = true` 并挂载 `UcgShell`；返回 page 0 后保持已挂载状态（避免重复 init）
- [x] 2.3 确认 `UcgEnterSquareTab` 的 `ucgRepositoryProvider` watch 仍工作且不触发定位

## 3. 广场 Feed（`ucg-square-feed`）

- [x] 3.1 `UcgSquareTab._load` refresh 路径调用 `ensureUcgLocationForDistance` 后再请求 Feed
- [x] 3.2 关注 Tab refresh 同样走 consent；分页 load more 复用已缓存坐标
- [x] 3.3 在广场 Tab 集成 `UcgLocationSettingsHint`（拒绝后进入广场可见）

## 4. Compose 发帖（`ucg-compose-post`）

- [x] 4.1 `UcgComposeScreen._publish` 在 `createPost`/`updatePost` 前调用 `ensureUcgLocationForDistance`
- [x] 4.2 拒绝定位时仍完成发表（无 lat/lng）

## 5. 喂养历史同步广场（`history-event-square-sync`）

- [x] 5.1 `runHistoryEventMediaSideEffects` 增加可选 `lat`/`lng` 参数并传入 `createPost`/`updatePost`
- [x] 5.2 `home_history_edit_sheet` 保存且 sync 开启时先 `ensureUcgLocationForDistance`，再将坐标传入 side effects
- [x] 5.3 拒绝定位时同步发帖/更新仍完成（无 lat/lng）

## 6. 合规与平台配置

- [x] 6.1 更新 `app/ios/Runner/Info.plist` 定位用途文案为「用于展示动态与你的距离」（与 Dialog 一致）
- [x] 6.2 更新 `resource/public/privacy-policy.html`：可选 GPS 用于 UCG 距离；「我们不收集」移除 GPS；更新生效日期（见 `privacy-policy-gps-delta.md`，网关仓库无本地副本）
- [x] 6.3 在 change 或 PR 说明中记录 App Store Connect App Privacy 问卷需申报 Precise Location（App Functionality、非 Tracking、可选）— 提审前人工填写（见 `app-store-privacy-checklist.md`）

## 7. 验证

- [x] 7.1 冷启动停留喂养页：无定位弹窗、无广场 Feed 网络请求（可 log 或断点确认）
- [x] 7.2 首次进入广场：先用途 Dialog（若未授权）→ 系统定位框 → Feed 加载；拒绝后 Feed 仍可见且无距离角标
- [x] 7.3 同 session 再次进广场：不弹系统框，展示「去设置」
- [x] 7.4 喂养页开启同步广场保存：触发定位同意；拒绝仍同步成功
- [x] 7.5 Compose 发表：定位同意 + 拒绝降级
- [x] 7.6 `flutter analyze` 无新增 error

## 8. GPS 横幅与 App 权限横幅分离（`ucg-location-consent` 补丁）

- [x] 8.1 `ucgLocationHintKindProvider` 区分 `gpsServiceOff` / `appPermissionDenied`；GPS 关时不弹权限 Dialog、不设 `deniedThisSession`
- [x] 8.2 GPS 关横幅：「请先开启手机定位…」+「开启定位」→ `openLocationSettings()`；权限横幅：「允许位置权限…」+「去设置」→ `openAppSettings()`
- [x] 8.3 不增加 `resumed` 自动刷新；用户手动下拉刷新时 `ensure` 重检即可
