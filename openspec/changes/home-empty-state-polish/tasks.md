## 1. 基础准备

- [x] 1.1 在 `pubspec.yaml` 中添加 `lottie: ^3.1.2` 依赖
- [x] 1.2 执行 `flutter pub get` 更新依赖
- [x] 1.3 在 `assets/images/` 目录下创建动画资源占位并完成配置（待接入实际 3D 动画 JSON）

## 2. 主页显示逻辑重构

- [x] 2.1 修改 `HomeTodaySummaryPanel`：当 `totals.isEmpty` 时确保返回 `SizedBox.shrink()`
- [x] 2.2 在 `home_screen.dart` 中调整 `showBindBanner` 逻辑：当显示全屏 3D 引导时，该 Banner SHALL 保持隐藏
- [x] 2.3 在 `home_screen.dart` 的 `body` 渲染块中，引入状态切分：
    - `if (needsDeviceBind)` -> 展示绑定邀请视图
    - `else if (historyItems.isEmpty && historyInitialLoadDone)` -> 展示记录鼓励视图
    - `else` -> 展示原有的 `HomeHistoryScroll`

## 3. 空状态组件开发

- [x] 3.1 实现 `_HomeEmptyStateGallery` 私有组件：
    - 支持 Lottie 动画循环播放
    - 适配 3D 渲染风格的阴影与间距
    - 支持传入标题、副标题以及可选的操作按钮
- [x] 3.2 针对“已绑定无记录”场景，接入 `settingsBabyProvider` 以显示宝宝昵称

## 4. 验证与优化

- [ ] 4.1 验证在无网络/加载失败时，UI SHALL 平滑回退到文本提示
- [ ] 4.2 检查不同屏幕尺寸下的 3D 动画缩放比对
- [ ] 4.3 确认 Web 环境下动画渲染无明显卡顿
