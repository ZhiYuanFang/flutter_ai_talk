# Proposal: 广场 Feed 多图角标

## Why

广场双列 masonry 卡片仅展示首张封面图，用户无法从列表感知帖子含多张图片。

## What

在多图帖（`imageUrls.length > 1`）封面右下角叠加 `×N` 角标（N = 图片总张数），半透明黑底圆角 pill 保证任意背景可读。

## Scope

- `UcgMasonryFeedCard` / `_MasonryMedia`（推荐与关注 Feed）
- 不含「我的动态」九宫格、视频帖
