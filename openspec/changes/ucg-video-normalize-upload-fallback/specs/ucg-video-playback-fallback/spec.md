## ADDED Requirements

### Requirement: Inline CDN video playback failure SHALL offer external player

When `VideoPlayerController` fails to initialize or play a network `videoUrl` in UCG surfaces (`UcgInlineVideoPlayer`, fullscreen viewer, chat inline video), the client MUST show a user-visible failure state with a **「用系统播放器打开」** action (and MAY keep **重试**). Tapping the action MUST open the same URL via platform external playback: Android `Intent.ACTION_VIEW` with `video/*` on https URI; iOS and other platforms `url_launcher` with `LaunchMode.externalApplication`. Web MAY open URL in a new browser tab.

当 CDN 视频在内联 `VideoPlayer` 初始化或播放失败时，客户端 MUST 展示失败态并提供「用系统播放器打开」（可保留重试）。Android MUST 用 `ACTION_VIEW` 打开 https 视频；iOS MUST 用 `url_launcher` 外链打开。

#### Scenario: Feed inline video init failure shows external open

- **WHEN** 用户在广场/详情点击播放且 `VideoPlayerController.networkUrl` initialize 失败
- **THEN** UI SHALL 显示「用系统播放器打开」按钮
- **AND** 点击后 SHALL 打开该 `videoUrl` 外链播放

#### Scenario: Android fullscreen failure opens https URL

- **WHEN** 全屏页 `videoUrl` 非空且内联播放失败
- **THEN** 「用系统播放器打开」 MUST 传入 `videoUrl` 而非仅 local filePath

#### Scenario: Compose local preview keeps existing filePath open

- **WHEN** compose 本地预览失败且仅有 `filePath`/`contentUri`
- **THEN** 现有 Android `openSystemPlayer` 行为 MUST 保持可用

#### Scenario: Web inline failure may open new tab

- **WHEN** Web 端内联视频失败且用户点击外链
- **THEN** Client MAY 使用 `launchUrl` 在新标签打开 CDN URL
