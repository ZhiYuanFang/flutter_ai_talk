## ADDED Requirements

### Requirement: 横屏 KWS 模型主源 MUST 为自有 CDN mobile 包

When the landscape wake engine needs on-device KWS model files that are not already complete under the app support directory, the client MUST download the archive from the first-party CDN URL for the Wenetspeech **mobile** package (`https://resorce.cuplay.top/app/models/kws/sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile.tar.bz2` or an equivalent `--dart-define` override of the same object), and MUST NOT use GitHub Releases as the primary download source. 当横屏唤醒引擎需要本地 KWS 模型且应用支持目录尚未齐全时，客户端 MUST 从自有 CDN 下载 Wenetspeech **mobile** 压缩包（上述 URL 或等价 dart-define 覆盖），MUST NOT 以 GitHub Release 作为主下载源。

#### Scenario: 缺失模型时从 CDN 下载

- **WHEN** 预测横屏启动唤醒且本地 KWS 模型不完整
- **THEN** 客户端 MUST 向自有 CDN mobile 包 URL 发起下载
- **AND** MUST NOT 将 GitHub `k2-fsa/sherpa-onnx` Release URL 作为主源

#### Scenario: 本地已齐全则跳过下载

- **WHEN** 应用支持目录下 mobile 模型目录已含可用的 encoder、decoder、joiner 与 `tokens.txt`
- **THEN** 客户端 MUST NOT 再次下载压缩包
- **AND** MUST 仍确保关键词文件可供 KWS 使用

### Requirement: 本地路径 MUST 对齐官方 mobile 包布局

After extraction, the client MUST resolve model files under the top-level directory name matching the mobile archive (`sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile`). For each of encoder, decoder, and joiner, the client MUST prefer the `*.int8.onnx` file when present, otherwise MUST use the corresponding fp32 `*.onnx` file. Completeness MUST allow mixed int8/fp32 across the three components. 解压后客户端 MUST 在与 mobile 包顶层目录名一致的目录下解析模型；encoder/decoder/joiner 各自优先 `*.int8.onnx`，否则用对应 fp32；完整性 MUST 允许三件混合精度。

#### Scenario: mobile 混合精度可判定齐全

- **WHEN** 目录中存在 `encoder-...int8.onnx`、`decoder-....onnx`（无 int8）、`joiner-...int8.onnx` 与 `tokens.txt`
- **THEN** 完整性校验 MUST 通过
- **AND** KeywordSpotter 配置 MUST 使用上述实际存在的三件路径

#### Scenario: 顶层目录名与包内一致

- **WHEN** 压缩包条目路径以 `sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile/` 开头
- **THEN** 解压落盘根目录 MUST 使用该 `-mobile` 目录名（不得仅认无 `-mobile` 的旧名）

### Requirement: KWS 模型准备失败 MUST 可观测

Download, decompress, or completeness failures for landscape KWS models MUST be recorded via `AppDebugLog` with a dedicated debug tag (e.g. `[LandscapeKws]`) including enough detail to diagnose (HTTP status and/or error kind and/or missing file basenames), and MUST surface a short user-readable reason through the existing landscape status caption path. Silent `catch` without logging is forbidden. 横屏 KWS 模型下载、解压或完整性失败 MUST 经带专用 tag 的 `AppDebugLog` 记录可诊断信息（HTTP 状态与/或错误类型与/或缺失文件名），并 MUST 经既有横屏状态文案路径给出简短可读原因；禁止无日志的静默 `catch`。

#### Scenario: HTTP 非成功

- **WHEN** CDN 下载返回非 2xx 或传输抛错
- **THEN** Debug 日志 MUST 记录失败（含 status 或 err）
- **AND** 左下角状态 MUST 提示模型下载/准备失败类短文案（可点按联调策略保持既有产品行为）

#### Scenario: 解压后缺文件

- **WHEN** 下载成功但解压后缺少 encoder/decoder/joiner/`tokens.txt` 之一
- **THEN** Debug 日志 MUST 标明缺失文件基名
- **AND** `ensureLandscapeKwsModels` MUST 返回失败（null/等价）且 UI 状态可读
