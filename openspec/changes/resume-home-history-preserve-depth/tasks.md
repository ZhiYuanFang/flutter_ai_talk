## 1. 合并纯函数与刷新分模式

- [x] 1.1 新增 page1 upsert + 保留「不在 page1 的本地更旧 id」+ pending 规则的纯函数（`history_mapper` 或邻近）
- [x] 1.2 `refreshFromRemote`（或等价）增加 `preserveLoadedDepth`；`false`=现网整表 page1；`true`=深度合并且 `highestPageLoaded` 不降为 1
- [x] 1.3 `preserveLoadedDepth: true` 成功时 `saveSnapshot` 写完整合并快照；`false` 保持现网瘦快照语义

## 2. 调用方接线

- [x] 2.1 `bootstrap()`（resume / deviceNo 变更等）使用 `preserveLoadedDepth: true`
- [x] 2.2 喂养显式下拉 / 底部上拉仍用默认 `false`（整表刷新最新一页）
- [x] 2.3 冷启动若走 `refreshFromRemote` 且磁盘已有多页：使用 `true`，避免首次远程砍深度

## 3. 验收对照

- [x] 3.1 对照 specs：resume 保留深度、手势仍可整表替换、深度合并落盘、range force 仍执行
- [x] 3.2 确认无 `app/android/**` 变更；未新增裸 `debugPrint`/`print`
