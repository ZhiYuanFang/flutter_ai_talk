## 1. 登录与鉴权（胖宝号 + 微信拦截）

- [x] 1.1 在 `AuthRepository` 增加 `signInWithDeviceNo(String deviceNo)`，并在 `RemoteAuthRepository` 中实现：`POST /device/app/api/device_login`，body `{ "device_no": trimmed }`，`withAuthorization: false`；解析 token 与 `deviceNo`/`device_no` 逻辑与 `signInWithWeChat` 对齐。
- [x] 1.2 重构 `LoginScreen`：默认展示胖宝号输入 + 主按钮登录；调用 `signInWithDeviceNo` 后复用现有 `refresh` / `loadBaby` / `context.go('/home')` 与错误 Toast。
- [x] 1.3 微信登录按钮点击仅设置 Toast「当前功能未开放」，不调用 `_performLogin`、不 `redirectToWeChatWebAuthorize`、不触发 fluwx。
- [x] 1.4 调整 Web `initState` 逻辑：移除或改写 `_tryResumeWebOAuth`，确保不会因待处理微信 code 自动走微信登录；若有残留 code，可选 Toast 引导使用胖宝号或清除 pending 状态（与 `wechat_web_redirect` / sessionStorage 工具对齐）。

## 2. Android APK 缓存下载与安装

- [x] 2.1 `pubspec.yaml` 增加 `path_provider`（及经 design 选定的安装辅助方式，如薄 MethodChannel 或经评估插件）。
- [x] 2.2 新增独立模块（如 `lib/update/android_apk_installer.dart` 或 `lib/platform/android_install.dart`）：从 URL 流式下载到 `getTemporaryDirectory()` 下子目录、固定/版本化文件名、下载中错误处理。
- [x] 2.3 Android `AndroidManifest.xml`：声明 `REQUEST_INSTALL_PACKAGES`（按需）、注册 `FileProvider`（`android:resource` 指向 `xml/file_paths.xml`），`file_paths` 包含 APK 缓存目录。
- [x] 2.4 实现 `FileProvider` URI + `Intent.ACTION_VIEW` 调起安装；处理 `canRequestPackageInstalls` 为 false 时跳转设置；捕获异常并 Toast。
- [x] 2.5 修改 `version_prompt.dart`：Android 分支改为「确认更新 → 显示进度（Dialog 或线性进度）→ 下载完成调起安装」；失败时 SnackBar/Toast；iOS/Web 行为保持不变。

## 3. 文档与校验

- [x] 3.1 更新 `app/README.md`：说明默认胖宝号登录、`device_login` 接口、微信未开放、Android 更新安装权限与厂商设置引导。
- [x] 3.2 运行 `dart analyze` / `flutter analyze` 确保无新增 error；真机或模拟器验证一次 Android 下载安装（HTTPS 测试包）。
