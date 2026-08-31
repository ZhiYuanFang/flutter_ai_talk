## Why

全屏 lightbox 开启 loading 时 `UcgNetworkImage` 同时设置 `placeholder` 与 `progressIndicatorBuilder`，触发 `octo_image` 断言崩溃。同时用户需要在大图态长按将当前图保存到系统相册；现网 lightbox 无保存入口。

## What Changes

- 修复 `UcgNetworkImage`：原生 `CachedNetworkImage` 在 `showLoadingIndicator` 时 **只** 使用 `progressIndicatorBuilder` **或** `placeholder` 之一，不得同时非 null；保持 lightbox 可见 loading 语义（基线全分辨率 loading 要求不变）。
- 在 `showUcgPhotoLightbox` / `showUcgLocalImageLightbox`（及等价 pinch 大图页）支持 **长按保存到相册**（原生）；成功/失败有用户可见反馈；拒绝权限可引导设置。
- Web：不写入系统相册；长按给出明确不支持或等价下载提示（实现择一，须产品可感知）。
- 复用既有 `photo_manager` 写图能力（优先，避免无必要新依赖）；写入权限与「读相册选图」区分处理。
- 不新建 `**/test/**`。

## Capabilities

### New Capabilities

- `ucg-network-image-loading`: 原生 CachedNetworkImage loading 指示器互斥约束（修 assert）。
- `ucg-lightbox-save-album`: 全屏图片 lightbox 长按保存到系统相册。

### Modified Capabilities

- （无强制改基线标题）全分辨率 lightbox loading 行为保持；本变更只修正实现互斥。

## Impact

- `app/lib/ucg/ui/widgets/ucg_network_image.dart`
- `app/lib/ucg/ui/widgets/ucg_media_viewer.dart`（lightbox 长按）
- 可能新增 `ucg_save_image_to_album.dart`（或等价）与权限辅助；Android/iOS 相册写权限文案与 `Info.plist` / Manifest 若缺则补。
- 若仅用已有 `photo_manager`，一般无新 AAR；若引入新 SDK 须按 project.md 做 release/R8。
