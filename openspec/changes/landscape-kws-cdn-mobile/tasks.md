## 1. Debug 白名单

- [x] 1.1 新增 `AppDebugLog.landscapeKws`（tag `[LandscapeKws]`）
- [x] 1.2 三联更新：`logcat_api_http.ps1`、`app/README.md` Debug 表

## 2. CDN 源与 mobile 路径

- [x] 2.1 将 `kLandscapeKwsModelArchiveUrl` 改为自有 CDN mobile 包 URL；`kLandscapeKwsModelDirName` 改为带 `-mobile` 的顶层名
- [x] 2.2 重写 `_pathsFor`：encoder/decoder/joiner 分件 prefer int8，否则 fp32；更新 `_isComplete`
- [x] 2.3 下载/解压/缺文件失败路径：`AppDebugLog.landscapeKws` + `onStatus` 短因（禁止静默吞错）

## 3. 文档与验收

- [x] 3.1 更新 `app/README.md` 预测横屏语音段落：模型主源改为 CDN mobile，不再写 GitHub 主下
- [ ] 3.2 真机（关代理）进预测横屏：进度可走完或日志可见失败因；齐全后左下角回到唤醒指引
