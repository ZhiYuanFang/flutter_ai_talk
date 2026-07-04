## ADDED Requirements

### Requirement: Debate compose SHALL capture topic and stance labels without media

The app MUST provide `UcgDebateComposeScreen` (or equivalent) reachable from the square FAB. Fields: topic `content` (unlimited length), `debateLeft` and `debateRight` (max 5 chars each, required). The screen MUST NOT show album picker, video picker, or presign upload controls. Successful publish MUST call `POST /posts` with `type: debate`.

辩论发帖页 MUST 仅含话题与左右标签，MUST NOT 含媒体选择。

#### Scenario: 发布辩论帖

- **WHEN** 用户填写话题与左右标签并提交

- **THEN** App SHALL POST `type: debate` 且无 `mediaKeys`

#### Scenario: 标签超长阻止提交

- **WHEN** 用户输入 6 字的立场标签

- **THEN** App SHALL 阻止提交并提示每侧最多 5 字

### Requirement: Square FAB SHALL replace dock compose entry

The square tab MUST show a floating action button for debate compose. The UCG bottom dock MUST NOT expose a compose/post entry for publishing (moment compose MAY remain reachable from profile or history sync only).

广场 MUST 以 FAB 发辩论；底部 Dock MUST NOT 再提供发帖入口。

#### Scenario: 广场 FAB 打开发帖

- **WHEN** 用户在广场点击 FAB

- **THEN** App SHALL 打开辩论 compose 屏

#### Scenario: Dock 无发帖

- **WHEN** 用户查看 UCG 底部 Dock

- **THEN** MUST NOT 展示原「发帖/发布」compose 入口

## MODIFIED Requirements

### Requirement: Compose SHALL support text with image or video limits

The compose screen for **`type=moment`** SHALL retain existing behavior: (a) text + up to 9 images, OR (b) text + 1 video with max duration 15 seconds and max size 20MB. **Debate compose** is a separate screen without media per ADDED requirement above. User MUST NOT submit both multi-image set and video in one moment post.

**moment** 发帖保留图文/视频规则；**debate** 发帖走独立无媒体流程。

#### Scenario: moment 超过 9 张图片

- **WHEN** 用户在 moment compose 尝试选择第 10 张图片

- **THEN** App SHALL 阻止并提示上限 9 张

#### Scenario: 辩论 compose 无九宫格

- **WHEN** 用户打开辩论 compose

- **THEN** App MUST NOT 展示图片九宫格或视频预览
