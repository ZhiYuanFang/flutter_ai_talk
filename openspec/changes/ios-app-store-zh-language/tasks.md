## 1. CI 脚本：声明 zh-Hans 本地化

- [ ] 1.1 在 `prepare_ios_project.sh` 的 Info.plist Python 块中写入 `CFBundleDevelopmentRegion=zh-Hans` 与 `CFBundleLocalizations`（含 `zh-Hans`）
- [ ] 1.2 同脚本生成 `ios/Runner/zh-Hans.lproj/InfoPlist.strings`（`CFBundleDisplayName`/`CFBundleName`，优先 `IOS_APP_DISPLAY_NAME`，默认「胖宝」）
- [ ] 1.3 （可选）在 `configure_ios_project.rb` 或脚本中 idempotent 补丁 `project.pbxproj` 的 `knownRegions` / `developmentRegion`

## 2. 文档

- [ ] 2.1 更新 `docs/github-ios-ipa.md`：说明 App Store「语言」来自 IPA bundle 本地化；上传新 build 后才会更新
- [ ] 2.2 更新 `docs/ios-github-actions-checklist.md`：提审清单增补「商品页语言为中文」自检项

## 3. 验证

- [ ] 3.1 本地或 CI 构建后检查 `Info.plist` 与 `zh-Hans.lproj/InfoPlist.strings` 内容符合 spec
- [ ] 3.2 跑 `build-ios-testflight` 或 `appstore` 上传新 build，在 ASC 确认 Included Localizations 含 Chinese (Simplified)
- [ ] 3.3 处理完成后检查 [胖宝 App Store 商品页](https://apps.apple.com/cn/app/%E8%83%96%E5%AE%9D/id6774418472)「语言」为中文
- [ ] 3.4 运行 `openspec validate ios-app-store-zh-language`
