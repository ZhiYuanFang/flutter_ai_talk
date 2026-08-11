## 1. Notifier 世代与清队列

- [x] 1.1 `HomeHistoryNotifier` 增加 epoch；`clearForSignOut` 递增 epoch、清空 `_queuedWhileFlyFrozen`、重置 `_warmFuture`，并视情况解除 fly freeze
- [x] 1.2 `_applyState` / `_setItemsNow`（及 refresh await 之后）校验 epoch，不匹配则丢弃写回
- [x] 1.3 `persistToDisk` 在写入前复核 epoch 与当前 `deviceNo`，避免 wipe 后回写磁盘

## 2. 未绑定空列表

- [x] 2.1 `_refreshFromRemoteImpl` / warm：已登录且无 `deviceNo` 时强制空列表 + memory clear，不得保留旧 items
- [x] 2.2 确认首页未绑定路径走空态引导，不再依赖「未绑定 + 非空列表」banner 展示旧数据

## 3. 校验

- [x] 3.1 `dart analyze` 触及文件无新增 error
- [ ] 3.2 手工：账号 A 有历史 → 切换账号 → 登录未绑定 B → 无旧时间线；绑定 B 后仅见 B 数据
