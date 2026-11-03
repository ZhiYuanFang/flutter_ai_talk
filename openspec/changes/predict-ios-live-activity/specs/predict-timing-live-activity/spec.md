## ADDED Requirements

### Requirement: iOS client SHALL present Timing Live Activity separately and only from push

For in-progress timing on iOS, the client MUST provide a Live Activity configuration separate from Imminent. The lock-screen UI MUST show logo, copy indicating timing in progress (计时中), a time display, and a trailing arrow. The client MUST NOT locally `Activity.request` (or equivalent) a Timing Live Activity for this product path; presentation and dismissal MUST wait for server Push-to-Start / liveactivity start and end as specified by twin `predict-live-activity-push`. Multiple Timing Live Activities MUST be displayable concurrently when the system presents multiple activities.

iOS 进行中计时 MUST 使用与 Imminent 分离的 Live Activity 配置。锁屏 MUST 含 logo、计时中语义、时间与右箭头。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Timing；展示与关闭 MUST 等待对端 `predict-live-activity-push` 的 start/end 推送。系统同时下发多条时客户端 MUST 能并存展示。

#### Scenario: Separate Timing type

- **WHEN** 同时存在 Imminent 与 Timing Live Activity
- **THEN** 二者 MUST 为不同 Activity 配置，MUST NOT 用 Imminent 组件实例表达计时中

#### Scenario: No local request for Timing

- **WHEN** 用户在本机开始一条计时且 App 仍在前台
- **THEN** 客户端 MUST NOT 仅凭本地开始动作创建 Timing Live Activity

#### Scenario: Multiple Timing activities

- **WHEN** 系统同时呈现两条不同 history 对应的 Timing Live Activity
- **THEN** 客户端锁屏 MUST 允许同时展示二者

### Requirement: Timing tap SHALL open the app

Tapping a Timing Live Activity MUST open the app. The client MUST NOT be required to end the Timing Live Activity on tap alone; end MUST come from server push when timing closes (twin `predict-live-activity-push`).

点击 Timing Live Activity MUST 打开 App。MUST NOT 要求仅点击即 end；结束 MUST 来自计时闭合时的服务端 end 推送（对端 change）。

#### Scenario: Tap opens app

- **WHEN** 用户点击 Timing Live Activity
- **THEN** App MUST 打开
- **AND** 客户端 MUST NOT 被要求仅因点击而 end 该 Timing Live Activity
