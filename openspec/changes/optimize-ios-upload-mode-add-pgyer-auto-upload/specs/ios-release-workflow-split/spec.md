# Spec Delta: ios-release-workflow-split

## ADDED Requirements

### Requirement: iOS 发布入口必须按分发目标拆分

The system SHALL provide separate iOS release workflows per delivery target.
系统必须提供独立的 `ad-hoc`、`testflight`、`appstore` 三个发布入口，入口语义与分发目标一一对应。

#### Scenario: 用户触发工作流时按目标选择入口

- **WHEN** 用户在 GitHub Actions 页面手动触发 iOS 发布
- **THEN** 用户可直接选择目标入口，而非在单一入口内再选择模式

### Requirement: 各入口必须仅暴露该目标需要的参数

Each workflow MUST expose only target-relevant dispatch inputs.
每个入口必须仅声明本目标必需的输入参数，不得暴露与当前目标无关的分发参数，以降低误填概率。

#### Scenario: ad-hoc 入口不显示 TestFlight 组参数

- **WHEN** 用户打开 `ad-hoc` 入口
- **THEN** 表单中不出现仅用于 TestFlight 的分组参数

#### Scenario: appstore 入口不显示蒲公英参数

- **WHEN** 用户打开 `appstore` 入口
- **THEN** 表单中不出现蒲公英上传相关参数

### Requirement: 三个入口必须复用统一构建核心

Separate entry workflows MUST share a reusable core build pipeline.
为避免逻辑漂移，三个入口必须通过统一核心流程复用签名、构建、导出与产物解析步骤。

#### Scenario: 核心构建步骤变更可被三个入口继承

- **WHEN** 核心流程中的公共构建步骤更新
- **THEN** 三个入口在不复制粘贴逻辑的前提下获得一致行为

### Requirement: 旧单入口工作流必须退场

The legacy single-entry iOS workflow MUST be retired once split workflows are available.
当 `ad-hoc`、`testflight`、`appstore` 三入口可用后，旧单入口工作流必须立即退场，不得继续作为可触发主入口。

#### Scenario: 新入口上线后旧入口不可继续使用

- **WHEN** 发布入口拆分上线
- **THEN** 旧入口被移除或改为明确失败提示，并指向三个新入口
