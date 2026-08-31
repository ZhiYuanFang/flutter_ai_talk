## Context

`UcgNetworkImage` 在 `showLoadingIndicator` 时同时传 `placeholder` 与 `progressIndicatorBuilder`，lightbox 全分辨率加载触发 `octo_image` assert。全屏图入口已统一到 `showUcgPhotoLightbox` / `showUcgLocalImageLightbox`；仓库有 `photo_manager` 读相册，无写相册封装。

## Goals / Non-Goals

**Goals:**

- 修 loading 互斥，lightbox 仍有可见 loading。
- 大图长按可保存到系统相册（iOS/Android）；权限与结果反馈清晰。
- Web 明确不支持系统相册写入（提示或下载）。

**Non-Goals:**

- 不做视频全屏「保存到相册」。
- 不改列表缩略图默认无 loading。
- 不新建 `**/test/**`。

## Decisions

### D1：loading 只保留 progressIndicatorBuilder

`showLoadingIndicator == true` 时仅设 `progressIndicatorBuilder`；`placeholder` 保持 null。Web 继续用 `loadingBuilder`。

### D2：保存挂在 lightbox，不散落各业务页

在 `_UcgPhotoLightbox` / `_UcgLocalImageLightbox`（或共享页面壳）上 `onLongPress` → 保存当前页图片。Feed/聊天/二维码等自动继承。

可选二次确认对话框「保存到相册？」——默认 **要确认**，降低误触；若实现时手感过重可改为直接保存 + Toast（tasks 默认确认）。

### D3：写图用 photo_manager.editor

优先 `PhotoManager.editor.saveImage(Uint8List)`（或当前版本等价 API），不引入 `gal` 除非 editor 不可用。

字节来源：

- 网络 URL：`CachedNetworkImage` 缓存文件 / `DefaultCacheManager` / HTTP GET
- 本地 bytes / file：直接读

### D4：写权限单独门闸

不假设 `ucgEnsureAlbumPermission`（偏读）足够。新增 `ucgEnsureAlbumWritePermission`（或扩展参数 `forWrite: true`）：requestPermissionExtend + 平台所需 photos/add-only；失败可 `openAppSettings`。

Android Manifest / iOS `NSPhotoLibraryAddUsageDescription`：缺则补。

### D5：Web

长按 Toast/SnackBar：「当前平台不支持保存到相册」；不做静默失败。

### D6：手势

长按与现有下拉关闭、点按、pinch 共存；缩放中长按仍可触发保存（保存原图像素，非屏幕截图）。

## Risks / Trade-offs

- [权限文案/审核] → 补 Info.plist / 说明仅保存用户主动选择的图。  
- [大图下载耗时] → 保存中 loading；失败 Toast。  
- [Android 分区存储] → 走 photo_manager editor，避免私有目录直写 MediaStore 手写。

## Migration Plan

- 纯客户端。回滚：恢复双 builder（不推荐）或去掉保存手势。

## Open Questions

- 无（确认对话框默认开启）。
