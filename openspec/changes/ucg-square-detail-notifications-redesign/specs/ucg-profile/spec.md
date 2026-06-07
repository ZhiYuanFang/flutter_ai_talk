## MODIFIED Requirements

### Requirement: 我的页 SHALL use Xiaohongshu-style profile layout

Profile and **我的动态** timeline behavior unchanged except: tapping a post photo on **我的动态** SHALL open `UcgPostDetailScreen` directly (not lightbox). The same immersive detail screen SHALL be used whether entry is from square feed or 我的动态. Owner delete on detail only per `ucg-interactions`.

#### Scenario: 我的动态点击进详情
- **WHEN** 用户在「我的动态」点击帖子行或图片
- **THEN** App SHALL 打开与广场相同的沉浸式详情页

#### Scenario: 我的动态图片不进 lightbox
- **WHEN** 用户在「我的动态」点击帖子内图片
- **THEN** App SHALL NOT 打开 lightbox

### Requirement: Feed and detail SHALL display author bio from API

Public feed cards SHALL show truncated author bio (2 lines). Detail page SHALL show **full** author bio without truncation below the nickname/header region. Bio text SHALL come from `authorBio` / `author.bio` on post DTO (server profile fallback when snapshot empty).

#### Scenario: Feed 简介两行
- **WHEN** 广场卡片作者 bio 超过两行
- **THEN** UI SHALL 截断并显示省略号

#### Scenario: 详情全文 bio
- **WHEN** 用户打开帖子详情
- **THEN** 作者 bio SHALL 完整展示不截断
