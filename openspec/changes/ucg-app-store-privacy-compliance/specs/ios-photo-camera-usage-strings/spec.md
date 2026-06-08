## ADDED Requirements

### Requirement: iOS 构建产物 MUST 包含相册与相机用途说明

The iOS release build MUST set non-empty `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` in `Info.plist` with user-facing strings explaining UGC compose media selection and capture.

iOS 发布构建 MUST 在 `Info.plist` 写入非空的 `NSPhotoLibraryUsageDescription` 与 `NSCameraUsageDescription`；文案 MUST 说明用途为 UGC 社区发帖时从相册选择或拍摄图片/视频，不得为空或笼统的「需要访问相册/相机」。

#### Scenario: CI 未覆盖时使用默认文案

- **WHEN** 执行 `app/tool/ci/prepare_ios_project.sh` 且未设置或为空 `IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION` / `IOS_CAMERA_USAGE_DESCRIPTION`
- **THEN** 脚本 MUST 写入内置默认文案至对应 plist 键
- **AND** 默认相册文案 MUST 提及从相册选择图片或视频用于社区发帖
- **AND** 默认相机文案 MUST 提及拍摄照片或视频用于社区发帖

#### Scenario: CI 通过环境变量覆盖

- **WHEN** 构建流程设置非空 `IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION` 或 `IOS_CAMERA_USAGE_DESCRIPTION`
- **THEN** `prepare_ios_project.sh` MUST 将非空值写入对应 plist 键

#### Scenario: 用户首次从相册选图发帖

- **WHEN** 用户在 UGC 发帖页触发相册选择且系统展示权限请求
- **THEN** 系统弹窗说明 MUST 与 `Info.plist` 中 `NSPhotoLibraryUsageDescription` 一致

#### Scenario: 用户首次使用相机拍摄发帖

- **WHEN** 用户在 UGC 发帖页触发相机拍摄且系统展示权限请求
- **THEN** 系统弹窗说明 MUST 与 `Info.plist` 中 `NSCameraUsageDescription` 一致

### Requirement: iOS 工作流 MUST 传递相册与相机 Secret

GitHub Actions iOS 构建工作流 MUST expose optional secrets `IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION` and `IOS_CAMERA_USAGE_DESCRIPTION` to `prepare_ios_project.sh`.

`.github/workflows/ios-build-core.yml` MUST 将 `IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION`、`IOS_CAMERA_USAGE_DESCRIPTION` 作为可选 env 传入 CI 脚本。

#### Scenario: 工作流 env 映射

- **WHEN** 维护者配置 GitHub Secrets 并触发 iOS 构建
- **THEN** 工作流 MUST 将上述 Secret 映射为同名环境变量供 `prepare_ios_project.sh` 读取
