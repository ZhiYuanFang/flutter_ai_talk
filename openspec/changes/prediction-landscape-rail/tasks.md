## 1. 瀑布列数参数化

- [x] 1.1 `_WaterfallCards` 增加 `columnCount`（默认 2），按 `i % columnCount` 分列

## 2. 横屏分栏 UI

- [x] 2.1 `Orientation.landscape` 分支：`Row` 左竖排身份栏 + 右 `Expanded` 三列瀑布
- [x] 2.2 左栏竖排昵称/月龄（尊重 `showAge`）；可滚动防溢出；无头像
- [x] 2.3 横屏不渲染调色盘、布局切换、留意/引导/3小时/底 tip
- [x] 2.4 横屏强制 compact 渲染（忽略 list 偏好）

## 3. 竖屏回归

- [x] 3.1 竖屏保持顶栏工具 + 双列瀑布 + 既有 chrome 路径

## 4. 校验与冒烟

- [x] 4.1 `openspec validate prediction-landscape-rail --strict`
- [ ] 4.2 手工：横屏左竖排+三列、无工具/留意；竖屏双列与顶栏正常；横屏偏好 list 仍见瀑布
