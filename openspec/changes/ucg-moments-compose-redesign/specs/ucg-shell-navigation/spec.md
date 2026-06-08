## MODIFIED Requirements

### Requirement: UCG shell SHALL provide five-item bottom navigation

UCG page（PageView index 1）SHALL provide bottom navigation with items: 广场、宝藏、+（发布）、消息、我的。中间「+」SHALL open compose flow without switching to a permanent fifth tab index. Bottom navigation MUST follow `ucg-visual-system` glass dock styling (floating pill, theme primary for selection), not default Material `BottomNavigationBar`. Short tap on「+」MUST open media entry flow per draft state (bottom sheet if no draft, direct compose if draft exists). Long press on「+」MUST open text-only compose mode.

UCG 底部导航须含五栏；「+」须按草稿状态分流（无草稿 bottom sheet、有草稿直达 compose）；长按须进入纯文字 compose。

#### Scenario: 切换广场与我的
- **WHEN** 用户点击底部「我的」
- **THEN** 壳 SHALL 显示个人页内容，且底部「我的」为选中态

#### Scenario: 无草稿短按加号展示 sheet
- **WHEN** 用户短按底部「+」且本地无 compose 草稿
- **THEN** App SHALL 展示 bottom sheet，含「拍摄」与「从手机相册选择」
- **AND** 选择并完成上传后 SHALL 进入 compose 且预填媒体

#### Scenario: 有草稿短按加号跳过 sheet
- **WHEN** 用户短按底部「+」且本地存在非空 compose 草稿
- **THEN** App SHALL 直接进入 compose 并恢复草稿
- **AND** App SHALL NOT 展示媒体来源 bottom sheet

#### Scenario: 长按加号纯文字发布
- **WHEN** 用户长按底部「+」
- **THEN** App SHALL 打开 text-only compose（隐藏新媒体 picker）
- **AND** 若存在草稿则 SHALL 恢复草稿内容

#### Scenario: 点击加号不打乱 Tab
- **WHEN** 用户通过「+」进入 compose 后返回
- **THEN** App SHALL 恢复先前 Tab 选中态

## ADDED Requirements

### Requirement: Compose entry bottom sheet SHALL offer capture and gallery sources

When no local draft exists, short-tap「+」SHALL present a bottom sheet with at least「拍摄」and「从手机相册选择」.「拍摄」SHALL support photo capture and video recording via device camera where platform allows.「从手机相册选择」SHALL support multi-image (up to 9) or single video selection with mutual exclusion enforced before compose opens.

无草稿时入口 sheet 须提供拍摄与相册；拍摄支持拍照/录像（平台允许时）；相册支持多图或单视频且互斥。

#### Scenario: 拍摄照片
- **WHEN** 用户在 sheet 选择「拍摄」并拍摄照片
- **THEN** App SHALL 上传并进入 compose，预填该图片

#### Scenario: 拍摄视频
- **WHEN** 用户在 sheet 选择「拍摄」并录制视频
- **THEN** App SHALL 校验时长与大小后上传并进入 compose，预填该视频

#### Scenario: 相册多图
- **WHEN** 用户从相册选择多张图片
- **THEN** App SHALL 上传所选图片（不超过 9 张）并进入 compose

#### Scenario: 相册单视频
- **WHEN** 用户从相册选择视频
- **THEN** App SHALL 上传视频并进入 compose，且 SHALL NOT 同时预填图片

#### Scenario: Web 拍摄降级
- **WHEN** 客户端运行在 Web 且相机不可用
- **THEN** App MAY 隐藏或禁用「拍摄」并仅提供相册选择
