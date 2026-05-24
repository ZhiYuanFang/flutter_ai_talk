## Context

- HTTP 客户端基址：`AppEnv.apiBaseUrl`（默认 `http://www.cuplay.top:9702`，与 `authorizedApiClientProvider` 一致）。
- 服务端返回示例：
  - 事件 `logo`: `"/ai_talk_images/event_1_xxx.png"`
  - 版本 `downloadUrl`: `"/device/app/apk/foo.apk"`
- 现状：`event_catalog_paths.resolveEventLogoUrl` 已做 `base + path` 拼接；`RemoteVersionRepository` 将 `downloadUrl` 原样写入 `VersionInfo.androidApkUrl`，`version_prompt` 要求 `http`/`https` scheme，相对路径被判无效。

## Goals / Non-Goals

**Goals:**

- 单一函数 `resolveGatewayAbsoluteUrl(String? raw)`（命名可微调）供 logo、APK 及后续资源复用。
- 规则：trim 后为空 → `null`；已是绝对 URL → 原样；否则 `normalize(apiBaseUrl) + '/' + normalizePath(path)`。
- 版本检查在构造 `VersionInfo` 时解析 `downloadUrl`。
- `resolveEventLogoUrl` 改为薄封装或 `@Deprecated` 转调统一函数，避免双份逻辑。

**Non-Goals:**

- 不改网关 path、不改 APK 安装原生流程。
- 不处理需签名/鉴权才能访问的图片（若 403 另开变更）。
- 不将 `apiBaseUrl` 改为仅 `Uri.origin`（除非联调证明 API 带 path 前缀且资源在站点根；当前与既有 logo 实现一致，用完整 `apiBaseUrl` 去尾斜杠后拼接）。

## Decisions

### 1. 拼接算法（与现有 logo 一致）

```dart
String? resolveGatewayAbsoluteUrl(String? raw) {
  // empty → null
  // startsWith http:// or https:// → return trimmed
  // else: base = apiBaseUrl without trailing slashes
  //       path = raw without leading slashes
  //       return '$base/$path'
}
```

放置位置：`app/lib/api/gateway_absolute_url.dart`（与 `gateway_json.dart` 同层，便于仓库层引用）。

### 2. 消费点

| 消费点 | 时机 |
|--------|------|
| `parseEventOptionsList` / `EventCatalogStore.downloadLogo` | 保持经 `resolveEventLogoUrl` → 转调统一函数 |
| `RemoteVersionRepository.checkForUpdate` | `readGatewayStr` 后立即 `resolveGatewayAbsoluteUrl` |
| `version_prompt`（可选） | 下载前再 resolve 一次防御 |

### 3. 校验

`version_prompt` 的 `Uri.tryParse` + scheme 检查在 resolve 之后执行；`/device/...` 解析后应为 `http://host:9702/device/...`。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| `API_BASE_URL` 含 path 前缀时资源路径在站点根 | 与产品确认；若需 `Uri.origin` 再单独立项 |
| 双斜杠 | base 与 path 均 normalize |
| Mock 版本仍用绝对 URL | mock 不变 |

## Migration Plan

无数据迁移；发版后相对 `downloadUrl` 自动可用。已缓存的 `catalog_v1.json` 中若存了未 resolve 的 logo（旧 bug），刷新目录后覆盖。

## Open Questions

无（与联调约定：相对路径相对 `apiBaseUrl` 主机根拼接）。
