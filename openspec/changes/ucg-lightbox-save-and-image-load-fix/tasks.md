## 1. 修 loading 互斥

- [x] 1.1 `UcgNetworkImage`：`showLoadingIndicator` 时仅设 `progressIndicatorBuilder`，`placeholder` 为 null
- [ ] 1.2 手测：打开 lightbox 远程大图无 octo_image 断言，仍见 loading

## 2. 保存到相册

- [x] 2.1 封装写权限 + `PhotoManager.editor`（或等价）保存 Uint8List；补齐 iOS/Android 相册写权限声明若缺
- [x] 2.2 从 URL / 本地 path / bytes 取图字节（优先缓存）
- [x] 2.3 lightbox 长按 → 确认对话框 → 保存 → Toast；Web 可见「不支持」
- [ ] 2.4 确认下拉关闭与 pinch 仍可用

## 3. 验收

- [ ] 3.1 lightbox 加载无崩溃；列表缩略图默认仍无强制 spinner
- [ ] 3.2 原生长按可保存到相册；拒权有提示；`openspec validate ucg-lightbox-save-and-image-load-fix --strict`
