## 1. 默认值与工程文件

- [x] 1.1 将 `IOS_DEPLOYMENT_TARGET` 默认从 15.0 改为 17.0：`prepare_ios_project.sh`、`configure_ios_project.rb`、`align_spm_ios_platforms.sh`（及注释中主 App=15 叙述）
- [x] 1.2 更新仓库内 `app/ios/Flutter/AppFrameworkInfo.plist` 的 `MinimumOSVersion` 为 17.0
- [x] 1.3 更新 `app/ios/Runner.xcodeproj`（及相关已提交配置）中 Runner 的 `IPHONEOS_DEPLOYMENT_TARGET` 为 17.0；确认 Widget 仍为 17.0 且不被改低

## 2. CI 与文档

- [x] 2.1 更新 `.github/workflows/ios-build-core.yml`（及其他写死 `IOS_DEPLOYMENT_TARGET: '15.0'` 处）为 `17.0`
- [x] 2.2 更新 `docs/github-ios-ipa.md`、`app/ios/PangbaoWidget/README.md` 等「主 App 默认 15.0」说明为 17.0，并注明对齐后覆盖 `mobile_scanner` 15.5 地板

## 3. 验收

- [x] 3.1 全局检索 iOS 部署语境下残留的主 App `15.0` 默认（脚本/CI/文档），确认无漏改
- [x] 3.2 在可跑 iOS 的环境或 CI 上验证：`prepare_ios_project.sh` + `pod install` 对含 `mobile_scanner` 的工程不再报 higher minimum deployment target
  - 本机为 Windows，未跑 `pod install`；平台默认已 17.0 > `mobile_scanner` 15.5，待下一次 macOS CI 确认
