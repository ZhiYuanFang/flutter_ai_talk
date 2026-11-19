## 1. Android 更新改官网

- [x] 1.1 增加官网更新 URL 常量（`https://www.pangbao.cuplay.top/`）
- [x] 1.2 `maybeShowVersionPrompt`：Android CTA 改为「去更新」，外部浏览器打开官网；去掉下载进度安装对话框
- [x] 1.3 停止从更新 UI 调用 `downloadAndInstallApkFromUrl`；可删或留死代码但 MUST 不可达
- [x] 1.4 更新弹窗文案：引导前往官网安装最新版（强制更新仍可禁「稍后」）

## 2. 拆除装包权限与原生通道

- [x] 2.1 `AndroidManifest.xml` 移除 `REQUEST_INSTALL_PACKAGES`
- [x] 2.2 删除或停用 `MainActivity` installer MethodChannel（`installApk` / 未知应用设置跳转）
- [x] 2.3 清理仅服务于 APK 更新的 cache 路径说明；**保留**其它业务仍需的 FileProvider
- [x] 2.4 更新 `app/README.md` 中 Android 应用内安装说明

## 3. geolocator 剔除收尾

- [x] 3.1 确认 `pubspec.yaml` 无 geolocator；`ucg_location.dart` 为桩
- [x] 3.2 `flutter pub get` + clean，确认 `GeneratedPluginRegistrant` 无 GeolocatorPlugin
- [x] 3.3 在 `kUcgHomePagerEnabled`（及定位桩文件头）写明「开通 UCG 时恢复 geolocator」清单
- [x] 3.4 代码静态扫描确认无 geolocator 依赖/插件注册（跳过 APK 扫包：`pubspec` 无包、`GeneratedPluginRegistrant` 无 GeolocatorPlugin、`ucg_location` 为桩）

## 4. 验证

- [x] 4.1 设置/主壳版本检查：有更新时 Android 打开官网；iOS/Web 路径不变
- [x] 4.2 代码静态扫描替代 release 打包验收（用户确认跳过慢速 APK build；Manifest / MainActivity / apk_update 删除路径 / registrant 已核对）
- [x] 4.3 人工确认 Manifest 无 `REQUEST_INSTALL_PACKAGES`
