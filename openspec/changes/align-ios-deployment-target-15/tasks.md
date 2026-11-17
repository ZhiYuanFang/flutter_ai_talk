## 1. 核对主 App 基线

- [x] 1.1 确认 `app/ios/Runner.xcodeproj/project.pbxproj` 各配置 `IPHONEOS_DEPLOYMENT_TARGET` 均为 15.0；若有残留 12.x/13.x 则改为 15.0
- [x] 1.2 确认 `prepare_ios_project.sh` 默认 `IOS_DEPLOYMENT_TARGET=15.0`，且会写入 Podfile `platform :ios` 与 post_install 的 Pod DT 同步

## 2. 修复签名脚本对 Widget 的覆盖

- [x] 2.1 修改 `configure_ios_project.rb`：Runner 使用 `IOS_DEPLOYMENT_TARGET`（默认 15.0）；PangbaoWidget 使用 `IOS_WIDGET_DEPLOYMENT_TARGET`（默认 17.0）或跳过改写 Widget DT
- [x] 2.2 确认 `ensure_pangbao_widget_target.rb` 仍默认写入 Widget DT=17.0，与主 App 分离

## 3. AppFrameworkInfo 与 ephemeral SPM 对齐

- [x] 3.1 在 `app/ios/Flutter/AppFrameworkInfo.plist` 写入 `MinimumOSVersion = 15.0`；`prepare_ios_project.sh` 幂等保证该键
- [x] 3.2 新增 `app/tool/ci/align_spm_ios_platforms.sh`：将 ephemeral `Package.swift` 中低于 `IOS_DEPLOYMENT_TARGET` 的 `.iOS("…")` 抬到基线（默认 15.0），已更高者不降
- [x] 3.3 在 `ios-build-core.yml`：`config-only` 后调用 align；`Build signed IPA` 改用 `flutter_build_ipa_with_spm_align.sh`（PATH 包装 xcodebuild）；`ensure_pangbao_widget_target.rb` 注入 Runner Build Phase 兜底

## 4. 文档与厂商 SDK

- [x] 4.1 更新 `docs/github-ios-ipa.md`（及必要时 PangbaoWidget README）说明：对齐默认 **15.0**，不要只升到 13；本地须跑 prepare
- [x] 4.2 补充文档：报错中的 target 可能是 SPM Package.swift；须跑 align 脚本 / 保证 AppFrameworkInfo
- [x] 4.3 确认不改动 `WechatOpenSDK` vendored podspec / MinimumOSVersion 的 12.0

## 5. 校验

- [x] 5.1 静态核对：Runner=15、AppFrameworkInfo=15、Widget 脚本=17、prepare 默认=15、workflow 含 align 调用
- [x] 5.2 `openspec validate align-ios-deployment-target-15 --strict` 通过
