# Tasks

## 1. 工作流结构拆分

- [x] 1.1 新建 iOS 复用核心工作流（`workflow_call`），抽取签名、构建、导出、IPA 解析公共步骤
- [x] 1.2 新建 `build-ios-adhoc.yml` 入口并仅保留 ad-hoc 相关 dispatch 输入
- [x] 1.3 新建 `build-ios-testflight.yml` 入口并仅保留 TestFlight 相关 dispatch 输入
- [x] 1.4 新建 `build-ios-appstore.yml` 入口并仅保留 ASC 上传相关 dispatch 输入

## 2. 分发链路实现与失败策略

- [x] 2.1 在 ad-hoc 入口接入蒲公英上传步骤并完成 API 鉴权参数映射
- [x] 2.2 将蒲公英上传步骤配置为硬失败（上传失败即 workflow 失败）并输出错误上下文（不强制输出安装短链）
- [x] 2.3 在 testflight 入口保留内部测试组分发能力但不设为必填，并校验 app-store 导出语义
- [x] 2.4 在 appstore 入口实现仅上传 ASC 的链路，禁止自动提审与自动发布

## 3. 配置与安全收敛

- [x] 3.1 梳理并按入口最小化 secrets 传递范围（ad-hoc 与 ASC/TestFlight 分层）
- [x] 3.2 为三个入口补充必填参数校验与一致性校验（导出语义、签名材料、上传凭据）
- [x] 3.3 为公共参数统一命名（如 `flutter_version`、`build_name`、`build_number`）并对齐默认值策略

## 4. 迁移与验证

- [x] 4.1 让旧单入口工作流立即退场（删除或改为明确失败提示并指向新入口）
- [x] 4.2 更新发布文档，说明 ad-hoc/testflight/appstore 三入口职责、触发方法与 testflight 测试组“可选”语义
- [x] 4.3 优化 [docs/github-ios-ipa.md](docs/github-ios-ipa.md)，补充蒲公英凭据在 Repository Secrets 的配置步骤与字段说明
- [ ] 4.4 分别执行三条入口的手动验证：ad-hoc 上传蒲公英、testflight 上传测试、appstore 上传 ASC
- [ ] 4.5 验证异常路径：蒲公英上传失败时 ad-hoc 必须失败，且日志可定位原因
