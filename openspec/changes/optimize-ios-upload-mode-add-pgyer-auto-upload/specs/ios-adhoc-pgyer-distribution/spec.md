# Spec Delta: ios-adhoc-pgyer-distribution

## ADDED Requirements

### Requirement: ad-hoc 工作流必须自动上传 IPA 到蒲公英

The ad-hoc workflow MUST upload the exported IPA to Pgyer automatically after build succeeds.
当 `ad-hoc` 入口完成签名与 IPA 导出后，系统必须自动调用蒲公英上传接口，不得要求人工二次上传作为主路径。

#### Scenario: ad-hoc 构建成功后自动触发上传

- **WHEN** 用户触发 `ad-hoc` 工作流且 IPA 构建成功
- **THEN** 系统自动执行蒲公英上传步骤并记录上传请求结果

### Requirement: 蒲公英上传失败必须阻断工作流

Pgyer upload failure SHALL fail the ad-hoc workflow.
当蒲公英上传返回错误（鉴权失败、网络失败、接口失败或响应格式异常）时，工作流必须以失败状态结束，不得降级为仅告警。

#### Scenario: 蒲公英返回失败码

- **WHEN** 上传步骤收到非成功响应或命令退出码非零
- **THEN** 工作流立即标记失败并在日志输出可操作的错误信息

### Requirement: 上传成功后必须输出可分发结果

Successful Pgyer upload MUST produce distribution metadata for operators.
当上传成功时，系统必须输出最小可追溯分发信息（如版本标识、构建号、上传状态），用于快速校验分发结果；系统不得将“安装短链/二维码链接”作为必需输出。

#### Scenario: 上传成功并产生日志摘要

- **WHEN** 蒲公英接口返回成功结果
- **THEN** 工作流在日志或 summary 中输出可追溯的分发结果字段

### Requirement: 蒲公英凭据必须通过 Repository Secrets 配置

Pgyer credentials MUST be sourced from GitHub Repository Secrets and validated before upload.
系统必须通过 GitHub Repository Secrets 注入蒲公英凭据，不得在工作流中硬编码凭据；上传前必须校验凭据存在性并在缺失时失败。

#### Scenario: 蒲公英凭据缺失时失败

- **WHEN** ad-hoc 工作流启动并检测到蒲公英必需凭据未配置
- **THEN** 工作流在上传前失败，并输出明确的 Secrets 配置指引

### Requirement: 文档必须说明蒲公英 Secrets 配置

The release documentation MUST describe required Pgyer secrets and configuration steps.
发布文档必须明确蒲公英所需 Repository Secrets 名称、配置位置与最小配置步骤，确保首次配置者可独立完成。

#### Scenario: 新维护者可按文档完成蒲公英配置

- **WHEN** 新维护者阅读 iOS 发布文档
- **THEN** 新维护者可根据文档在仓库 Secrets 中完成蒲公英凭据配置并触发 ad-hoc 上传
