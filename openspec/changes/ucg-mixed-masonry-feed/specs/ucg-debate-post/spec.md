## MODIFIED Requirements

### Requirement: Client debate detection SHALL use left and right labels only

The App MUST treat a post as debate when `debateLeft.trim()` and `debateRight.trim()` are both non-empty. The client MUST NOT use `type == 'debate'` as the primary UI gate. Server MAY still store `type` for indexing; client display logic MUST follow label rule.

前端 MUST 以左右标签均非空判定辩论帖，MUST NOT 依赖 type 字段。

#### Scenario: 有标签无 type 仍渲染辩论卡

- **WHEN** Feed 项含非空 debateLeft 与 debateRight
- **THEN** App SHALL 使用辩论 UI（VS 条、全宽 span）
- **AND** SHALL NOT 因 type 缺失降级为 moment 卡

#### Scenario: 仅一侧标签视为 moment

- **WHEN** Feed 项仅一侧标签非空
- **THEN** App SHALL 按 moment 展示
- **AND** 创建路径 MUST 已被服务端拒绝

### Requirement: Debate posts MAY include media

Debate posts MUST be allowed to attach images or one video on create/update. Feed debate cards MUST render media between topic text and `UcgDebateVsBar` when media present.

辩论帖 MUST 允许媒体；Feed 辩论卡 MUST 文案下展示媒体再 VS 条。

#### Scenario: 有图辩论帖 Feed 布局

- **WHEN** 辩论帖含图片
- **THEN** 全宽卡 SHALL 顺序展示：作者行 → 文案 → 媒体 → VS 条

#### Scenario: 个人中心辩论帖展示媒体

- **WHEN** 用户在「我的动态」或他人主页时间轴浏览含媒体的辩论帖
- **THEN** App SHALL 顺序展示：文案 → 媒体（同广场最多 3 图 +N 规则）→ VS 条
- **AND** 点击媒体 MUST 进入详情页（与 moment 一致）

## ADDED Requirements

### Requirement: Create post SHALL reject partial debate labels

When create request has exactly one of `debateLeft` / `debateRight` non-empty after trim, server MUST reject with invalid parameter and message indicating both sides required. When both non-empty, server MUST create debate post. When both empty, server MUST create moment post.

创建 MUST 拒绝半填立场；两侧均有值为辩论帖。

#### Scenario: 半填拒绝

- **WHEN** POST `/posts` 仅含 `debateLeft`
- **THEN** 服务端 MUST 返回 4xx 且提示补全另一方

#### Scenario: 双填成功

- **WHEN** POST `/posts` 含 debateLeft 与 debateRight
- **THEN** 服务端 MUST 持久化为辩论帖并 MAY 含 media
