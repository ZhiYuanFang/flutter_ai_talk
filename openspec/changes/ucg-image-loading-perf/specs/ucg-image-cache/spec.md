## ADDED Requirements

### Requirement: UCG 远程图片 MUST 使用磁盘与内存双层缓存

All UCG CDN remote images loaded through `UcgNetworkImage` or `UcgAvatar` SHALL use a disk-backed image cache (e.g. `cached_network_image`) in addition to in-memory caching. List surfaces, avatars, and feed thumbnails MUST benefit from cache hits across app restarts and scroll-back without re-downloading identical URLs.

所有经 `UcgNetworkImage` / `UcgAvatar` 加载的 UCG CDN 远程图片必须使用带磁盘持久化的图片缓存（如 `cached_network_image`），在杀进程重进、列表滚回时已加载 URL 时应优先命中缓存而非重新下载。

#### Scenario: 杀进程重进后列表图命中磁盘缓存

- **WHEN** 用户曾浏览广场 feed 并加载过某帖 `thumbnailUrl`，随后完全退出 App 再次进入同一 feed
- **THEN** 相同 URL 的图片 SHALL 优先从磁盘缓存展示，且 MUST NOT 重复发起完整网络下载（除非缓存被系统清理）

#### Scenario: Web 仍经统一组件加载

- **WHEN** 用户在 Web 端浏览 UCG 且 CDN 图片可正常加载
- **THEN** App SHALL 仍通过 `UcgNetworkImage`/`UcgAvatar` 展示，且 MUST 保持既有 Web HTML-element / CORS 兼容策略

### Requirement: 列表表面图片 SHOULD 按显示尺寸解码

When `UcgNetworkImage` is given explicit `width` and/or `height` for list/grid/avatar surfaces, the implementation SHALL pass decode cache dimensions scaled by device pixel ratio (`memCacheWidth` / `memCacheHeight`) to avoid decoding full-resolution bitmaps for small on-screen cells.

当调用方为列表格子或头像传入明确 `width`/`height` 时，实现必须按设备像素比计算解码缓存尺寸，避免为小格子解码过大位图。

#### Scenario: 瀑布流封面按格子尺寸解码

- **WHEN** 瀑布流卡片以约半屏宽展示封面图并传入宽高
- **THEN** 图片解码尺寸 SHALL 与 on-screen 逻辑尺寸 × DPR 相当，且 MUST NOT 按原图像素全尺寸解码

#### Scenario: 大图 lightbox 不强制缩略解码

- **WHEN** 用户在 lightbox 中查看全分辨率 `cdnUrl` 且未传入固定宽高
- **THEN** 实现 MAY 省略 `memCacheWidth`/`memCacheHeight` 以保留全图清晰度
