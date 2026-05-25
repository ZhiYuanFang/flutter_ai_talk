## Context

- 短时反馈两条路：`apiToastProvider` → `PangbaoApp` 监听 → 默认 `SnackBar`；各页面零散 `ScaffoldMessenger.showSnackBar`。
- 已有 `appScaffoldMessengerKey` 全局 `ScaffoldMessenger`，主页底部为输入区，底部 SnackBar 易遮挡。
- 主题：`AppVisualTokens.onShell`、`colorScheme`、深色 shell（夜空等）需保证雾面字可读。

## Goals / Non-Goals

**Goals:**

- 统一顶部居中轻提示：圆角雾面、透明感、快速消失。
- 成功/信息 **1s**，错误 **2s**。
- 单入口 `showAppToast`；`apiToastProvider` 与直接 SnackBar 调用点全部迁移。
- 新提示顶替旧提示，避免连点堆叠。

**Non-Goals:**

- 不改 Dialog、BottomSheet、版本强制更新弹窗。
- 不引入第三方 toast 库（MVP）。
- 不改 Repository 业务文案字符串（仅展示层）。

## Decisions

### 1. 实现载体：定制 floating SnackBar（方案 A）

在 `appScaffoldMessengerKey` 上 `showSnackBar`，配置：

- `behavior: SnackBarBehavior.floating`
- `margin`: 顶部安全区 + 12px，水平居中（宽度 `wrap content`，最大宽约屏宽 85%）
- `backgroundColor: Colors.transparent`，`elevation: 0`
- `content`: 自定义 `DecoratedBox` 雾面 + `Text`

**理由**：复用现有 key 与无障碍播报；比自建 Overlay 队列改动小。  
**备选**：根 Overlay — 视觉更自由，本期不采用。

### 2. 雾面样式

- 容器：`BorderRadius.circular(12)`，`ClipRRect`
- 填充：`onShell` 或 `surface` 的 **8–12% alpha**（实现取 `onShell.withValues(alpha: 0.1)` 或 `Color.alphaBlend` 与 `shellColor`）
- 可选 1px 描边：`onShell` 15% alpha
- 文字：`onShell` 92–100% alpha，`fontSize` 14，`fontWeight` w500
- 可选轻 `TextShadow` 增强深色 shell 上对比

### 3. 时长分档 `AppToastTone`

| Tone | 默认时长 | 典型场景 |
|------|----------|----------|
| `success` / `info` | **1000 ms** | 已记录、已保存、已删除 |
| `error` | **2000 ms** | API 业务错误、网络异常、校验失败 |

`showAppToast(message, {AppToastTone tone = AppToastTone.info})`

`apiToastProvider` 默认 `info`（1s）；Repository 错误可增 `apiToastErrorProvider` 或在 notifier 封装 `showApiError(msg)` 设 `error` tone — **实现建议**：扩展 provider 为 `({String? message, AppToastTone? tone})` 或两个 provider；为减少调用方改动，`_toast` 错误路径传 `tone: error`。

### 4. 顶替策略

`showAppToast` 前 `clearSnackBars()`，再显示新条，保证同时仅一条。

### 5. 迁移映射

| 现调用 | 迁移后 |
|--------|--------|
| `apiToastProvider.state = msg` | listen → `showAppToast(msg, tone: info)`；错误 helper → `tone: error` |
| 各页 `SnackBar` 短文案 | `showAppToast(...)` 同 tone 规则 |
| 校验/保存失败 | `error` 2s |
| 「已记录」「已保存」 | `info` 1s |

### 6. 无障碍

保留 SnackBar 的 `content` 文本；`duration` 与 `MediaQuery.disableAnimations`：若系统减少动画，可缩短或取消进入动画（`SnackBar` 默认行为可接受）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 雾面在浅色背景下过淡 | 用 `onShell` + 描边/阴影；实机两套主题抽检 |
| 1s 过短读不完长错误 | 错误固定 2s；超长文案省略或截断（单行 `maxLines: 2`） |
| 与顶部状态栏/刘海重叠 | `margin.top = padding.top + 12` |

## Migration Plan

1. 实现 `app_toast.dart` + tone/duration。
2. 改 `app.dart` listen。
3. 批量替换 SnackBar 调用点。
4. 手工：主页已记录、API 错误、详情校验、登录错误。

## Open Questions

（无 — 用户已确认：成功 1s / 错误 2s / 圆角雾面。）
