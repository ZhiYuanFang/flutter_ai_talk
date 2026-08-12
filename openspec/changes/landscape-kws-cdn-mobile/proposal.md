## Why

预测横屏唤醒依赖首次从 GitHub Release 下载 Wenetspeech KWS 压缩包；国内真机到 GitHub 不稳定，且失败路径被 `catch (_)` 静默吞掉，用户只看到「唤醒模型准备失败」。运维侧已将 **mobile** 包托管到自有 CDN（`resorce.cuplay.top`）并验通，但客户端仍指向 GitHub 全量包，且路径选择与 mobile 包（顶层目录带 `-mobile`、encoder/joiner int8 + decoder fp32）契约不一致，即使改 URL 也会在解压后判不完整。

## What Changes

- KWS 模型主下载源改为自有 CDN 上的 **mobile** `tar.bz2`（GitHub 可选作回退，非必须本期落地）。
- 本地落盘目录与路径解析对齐官方 mobile 布局：顶层 `...-mobile/`；按件选择 int8（缺则该件用 fp32）。
- 下载/解压/完整性校验失败 MUST 经 `AppDebugLog` 记录可诊断信息，并在左下角状态给出可读短因（不再静默 `null`）。
- 更新 README 中「模型从 GitHub 下载」表述。

## Capabilities

### New Capabilities

- `landscape-kws-models`: 横屏唤醒 KWS 模型分发（CDN 源）、mobile 包路径契约、下载/解压失败可观测。

### Modified Capabilities

- （无）基线 `v2.1.0` 尚未合并 `prediction-landscape-voice` 的模型分发细则；本变更以新能力规格约束模型准备行为。唤醒监听产品行为仍由既有/并行 voice change 覆盖。

## Impact

- 代码：`app/lib/voice/landscape_kws_models.dart`（URL、目录名、`_pathsFor`、错误日志）；可能触及 `landscape_wake_word.dart` / `landscape_voice_provider.dart` 状态文案透传；`app_debug_log.dart` + `logcat_api_http.ps1` + `app/README.md` Debug 表（新 tag 三联）。
- 运维：依赖已上传对象 `https://resorce.cuplay.top/app/models/kws/sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile.tar.bz2`（约 15MB）；本变更不改 OSS 上传流程。
- 无新 pub 依赖；无 Android Manifest / R8 变更预期。
