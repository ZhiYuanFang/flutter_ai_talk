## Context

预测横屏唤醒（`SherpaLandscapeWakeWord` + `ensureLandscapeKwsModels`）首次需要本地 Wenetspeech KWS 模型。现行实现从 GitHub Release 拉全量 `tar.bz2`（~31MB），失败全部 `catch (_)` 吞掉。国内真机到 GitHub 不稳定；运维已将官方 **mobile** 包（~15MB）放到 `https://resorce.cuplay.top/app/models/kws/sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile.tar.bz2` 并 HEAD 验通。探包确认顶层目录为 `...-mobile/`，且仅有 `encoder/joiner` 的 int8 与 `decoder` 的 fp32——与当前「全 int8 或全 fp32」路径逻辑不兼容。

约束：Debug 日志须走 `AppDebugLog` 三联白名单；不引入新网络栈；不改唤醒词产品语义。

## Goals / Non-Goals

**Goals:**

- 主下载源改为自有 CDN mobile 包，国内可达。
- 落盘目录名与 `_pathsFor` 对齐 mobile 契约（分件 int8/fp32）。
- 下载/解压/缺文件失败可观测（日志 + 左下角短因）。
- README / Debug 表与实现一致。

**Non-Goals:**

- 本期不强制实现 GitHub 多源回退（可留常量注释或后续）；不以第三方镜像（ModelScope/ghproxy）为正式源。
- 不把模型打进 APK/IPA assets。
- 不改 KWS 关键词、阈值、阈值阈值或 chat WS 行为。
- 不在本 change 上传/运维 OSS（对象已就绪）。

## Decisions

1. **主 URL 写死 CDN mobile 包**  
   `kLandscapeKwsModelArchiveUrl` → `https://resorce.cuplay.top/app/models/kws/sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile.tar.bz2`。  
   备选曾考虑：仅换 GitHub mobile URL（体积变小但国内仍不稳）；ModelScope 优先（多依赖、URL 形态散文件）。选定自有 CDN 与业务媒体同域族（`resorce.cuplay.top`）。

2. **本地目录名改为带 `-mobile` 的官方顶层名**  
   `kLandscapeKwsModelDirName = 'sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile'`，与 tar 内 `file.name` 一致，避免解压到错误路径。  
   备选：解压后 rename 到无 `-mobile` 名——多一步易错；不采用。

3. **路径选择：分件 prefer int8**  
   encoder / decoder / joiner 各自：若 `*.int8.onnx` 存在则用之，否则用对应 fp32 `*.onnx`。完整性要求三件 + `tokens.txt` 均存在（可为混合精度）。对齐 Sherpa mobile 说明（decoder 常仅 fp32）。

4. **可观测：新 Debug tag（建议 `[LandscapeKws]`）**  
   三联改：`app_debug_log.dart`、`scripts/logcat_api_http.ps1`、`app/README.md`。记录：HTTP status、received bytes、缺哪些文件、解压异常类型（截断，勿打完整本地绝对路径若过长可只打文件名）。`onStatus` 同步短中文因供 UI。禁止继续裸 `catch (_)` 无日志。

5. **不改下载协议**  
   继续 `package:http` 流式 GET + 现有进度节流；CDN 已返回 `Content-Length`，进度 % 可用。

## Risks / Trade-offs

- **[Risk] 用户设备上已有不完整/旧目录缓存** → 完整性失败时删除目标 root 后重下；或检测旧无 `-mobile` 目录可忽略（新目录名自然隔离）。  
- **[Risk] CDN 对象被误删/ACL 变私有** → 日志暴露 statusCode；运维恢复对象；客户端文案提示「模型下载失败」。  
- **[Risk] 整包内存解压大峰值** → mobile ~15MB，可接受；本期不改为流式 bz2。  
- **[Trade-off] 无 GitHub 回退** → 实现更简单；海外若 CDN 异常需运维或后续加回退。

## Migration Plan

1. 确认 CDN 对象仍 200 且 Content-Length≈15MB（已验通）。  
2. 合入客户端 URL + 目录 + 路径 + 日志。  
3. 真机清应用数据或换目录名后进预测横屏，观察左下角进度至「说你好胖宝」及 `[LandscapeKws]` 日志。  
4. 回滚：恢复 GitHub URL / 旧目录逻辑（体验回退到不稳定下载）。

## Open Questions

（无）CDN URL、mobile 目录名、分件 int8、Debug tag 已写死。
