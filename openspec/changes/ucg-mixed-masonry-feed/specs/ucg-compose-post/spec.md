## MODIFIED Requirements

### Requirement: Compose entry bottom sheet SHALL offer capture and gallery sources

When the user adds media **from within** `UcgComposeScreen` (image grid add control), the app MAY present capture/gallery flows per existing album picker rules. **Dock short-tap「+」** MUST NOT present `showUcgComposeEntrySheet` before compose; it MUST open `UcgComposeScreen` directly (draft-first when local draft exists).

Dock 短按 MUST 直达 compose；入口 sheet 仅作为 compose 内加媒体的可选路径，而非 Dock 必经步骤。

#### Scenario: Dock 短按直达 compose

- **WHEN** 用户在 UCG Shell 短按 Dock「+」且无本地草稿
- **THEN** App SHALL push `UcgComposeScreen` 全功能编辑页
- **AND** MUST NOT 先弹出拍摄/相册入口 sheet

#### Scenario: 有草稿跳过 sheet

- **WHEN** 用户短按 Dock「+」且存在非空本地草稿
- **THEN** App SHALL 直接打开 compose 并恢复草稿
- **AND** MUST NOT 弹出入口 sheet

#### Scenario: compose 内添加媒体

- **WHEN** 用户在 compose 页点击媒体添加控件
- **THEN** App MAY 打开拍摄或相册流程
- **AND** SHALL 将本地媒体预填至 compose grid

### Requirement: The compose screen SHALL allow text media and gated debate labels

The compose screen SHALL allow: (a) text + up to 9 images, OR (b) text + 1 video, in the primary content panel. **Debate** stance inputs MUST live in a **separate panel** below titled「辩论」with an adjacent Switch defaulting **OFF**. When Switch is OFF, stance fields MUST NOT be shown and publish MUST create a moment (MUST NOT send debate labels). When Switch is ON, stance fields MUST be shown; both `debateLeft` and `debateRight` (each max 5 chars) MUST be non-empty to publish—empty both sides MUST block publish with user-visible prompt; exactly one side non-empty MUST fail with complete-other-side message. Publish MUST use v1 `POST /ucg/app/api/posts` only.

发布页 MUST 图文与辩论分 panel；Switch 默认关；Switch ON 时双方立场必填。

#### Scenario: Switch OFF 发 moment

- **WHEN** 用户未开启辩论 Switch 并发布
- **THEN** App SHALL 创建 moment 帖
- **AND** MUST NOT 发送 debateLeft/debateRight

#### Scenario: Switch ON 双方为空拦截

- **WHEN** 用户开启辩论 Switch 但两侧立场均为空并点击发布
- **THEN** App SHALL 提示需填写双方立场
- **AND** MUST NOT 成功发帖

#### Scenario: 半填立场创建失败

- **WHEN** 用户开启辩论 Switch 且仅填写一侧立场并发布
- **THEN** App SHALL 展示需补全另一方的提示
- **AND** MUST NOT 成功发帖

#### Scenario: 辩论帖带图发布

- **WHEN** 用户开启 Switch、填写两侧立场并选择图片后发布
- **THEN** App SHALL POST v1 `/posts` 含 content、debateLeft、debateRight 与 media
- **AND** 服务端 SHALL 接受媒体与辩论标签共存

### Requirement: Compose draft SHALL persist debate switch and labels

`UcgComposeDraft` MUST persist `debateEnabled`, `debateLeft`, and `debateRight` alongside text and media keys. Restoring draft on compose open MUST restore Switch state and stance text. Legacy drafts without these fields MUST default to Switch OFF and empty labels.

草稿 MUST 记住辩论 Switch 与立场文案。

#### Scenario: 草稿恢复辩论状态

- **WHEN** 用户存草稿后关闭 App 再打开 compose
- **THEN** App SHALL 恢复 debateEnabled 与左右立场文案
- **AND** Switch ON 时 SHALL 展示立场输入区

### Requirement: Compose debate inputs SHALL remain visible above keyboard

When debate Switch is ON and the user focuses a stance field, the compose scroll view MUST lift using the **entire debate panel** (title, Switch, and stance inputs) as the scroll anchor bottom, so the whole module sits above the system keyboard and emoji accessory bar. The page MUST use explicit scroll control with dynamic bottom padding that grows with keyboard inset.

辩论立场输入聚焦时 MUST 以整个辩论 panel 外框底边为锚点顶起，避免模块被键盘或 emoji 条遮挡。

#### Scenario: 辩论输入不被键盘遮挡

- **WHEN** 用户开启辩论 Switch 并聚焦左方或右方立场输入
- **THEN** App SHALL 滚动 compose 列表使整个辩论 panel 位于键盘与 accessory 上方可见
- **AND** 键盘 inset 动画期间 SHALL 再次顶起以保持可见

## REMOVED Requirements

### Requirement: Debate compose screen SHALL be the primary square publish entry

**Reason**: Superseded by unified Dock + → `UcgComposeScreen` with optional debate fields.

**Migration**: Remove `UcgDebateComposeScreen` from square FAB; delete square FAB.

### Requirement: Debate stance fields SHALL inline inside the primary compose glass panel

**Reason**: UX pivot — debate is a separate gated module with Switch.

**Migration**: Move stance inputs to second panel below media; default Switch OFF.
