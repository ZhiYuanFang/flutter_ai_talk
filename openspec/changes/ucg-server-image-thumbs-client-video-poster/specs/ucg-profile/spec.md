## MODIFIED Requirements

### Requirement: Profile API SHALL expose social stats and avatar update

`GET /profile/me` and `GET /profile/{wxId}` responses SHALL include `followingCount`, `followerCount`, and `postCount` when computed server-side. Authenticated requests to `GET /profile/{wxId}` SHALL include `isFollowing` for the viewer relative to the profile owner. Avatar change on 我的页 SHALL use single-image picker (`pickImage`) and `PUT /profile/me` with `avatarKey`. When `avatarKey` is present, responses MUST also include `avatarThumbnailUrl` built server-side via `BuildImageThumbnailURL` for list-surface display alongside full-resolution `avatarUrl` for profile header/home only.

#### Scenario: 我的页关注数展示
- **WHEN** 已登录用户打开「我的」且已关注他人
- **THEN** 关注 stat chip SHALL 显示服务端 `followingCount`（非零），关注/取关后 SHALL 刷新

#### Scenario: 点头像换头像
- **WHEN** 已绑定微信用户在「我的」页点击头像并选择图片
- **THEN** App SHALL 打开系统选图器、上传并调用 `PUT /profile/me` 更新头像

#### Scenario: 他人主页取关
- **WHEN** 已登录用户打开已关注用户的主页
- **THEN**「关注」按钮 SHALL 展示「已关注」且为浅色底；点击后 SHALL 调用 `DELETE /follow/{wxId}` 并更新为实心「关注」

#### Scenario: Profile header avatar uses full resolution
- **WHEN** 「我的」或他人主页头部展示头像（`ucg_profile_header.dart`）
- **THEN** App SHALL 加载全分辨率 `avatarUrl`
- **AND** Client MUST NOT 对 `avatarUrl` 自行追加 OSS resize

#### Scenario: List surface avatars use thumbnail
- **WHEN** Feed 作者头像、点赞网格、关注/粉丝列表、消息 Tab、会话列表、聊天 AppBar 或聊天气泡等列表 surface 展示用户头像
- **THEN** App SHALL 加载 `avatarThumbnailUrl`（或 `peerAvatarThumbnailUrl`）
- **AND** Client MUST NOT 在列表 surface 加载全分辨率 `avatarUrl`
