## 1. Wipe 入口

- [ ] 1.1 新增 `wipeAccountLocalState`（或等价）接受 `ProviderContainer`：快照 dn/babyId → session 已清或由调用方先 signOut → clear channel/deviceNo → `feed.clearCache` → `HomeHistoryMemoryCache.clear` → 清空 `homeHistory` 状态 → 删宝宝 prefs / 头像 → invalidate `settingsBabyProvider`（及头像相关）
- [ ] 1.2 明确 **不得** 调用凭据历史 store 的清除 API

## 2. 接入账号管理

- [ ] 2.1 切换账号：在现有 host/container 流程的 finally 中调用 wipe（保留 transports release + 宿主 `go('/login')`）
- [ ] 2.2 注销成功路径：用同一 wipe 替代零散 clear；保留注销专属的凭据条目移除；跳转仍宿主安全

## 3. 校验

- [ ] 3.1 `dart analyze` 触及文件无新增 error
- [ ] 3.2 手工：切号后新登录不得短暂出现上一宝宝昵称/旧喂养列表；凭据建议列表仍在
