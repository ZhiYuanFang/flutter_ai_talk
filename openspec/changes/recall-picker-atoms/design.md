## Context

量身定做 `_pickLastAt` / `_pickInterval` 使用 `showCupertinoModalPopup` + 系统背景。添加 number 事件使用 `HomeHistoryTimeField`（玻璃时分 Sheet）与带 `fieldFill` 框的 `HomeEventNumberPicker`（单滚轮）。产品要求间隔与用量 Sheet 一致（单滚轮单选），时间也走玻璃原子。

## Goals / Non-Goals

**Goals:**

- 间隔：玻璃 Sheet + 单列滚轮 + 确认；档位仍 15–720 分钟步进 15；文案仍 `_formatInterval`。
- 时间：玻璃入口，能选过去日期+时刻（`maximumDate: now`）；视觉与添加事件时间轮一致。
- 抽出共用单滚轮壳，避免间隔/用量各抄一套。

**Non-Goals:**

- 不把间隔数值改成用量 ml 档。
- 不在量身定做增加「喂养用量」字段。
- 不强制把添加事件时分改成日期时间（添加事件仍可锚定当天）。

## Decisions

1. **单滚轮原子**  
   新增如 `showGlassSingleWheelPickerSheet`（名可微调）：`showGlassAdaptiveBottomSheet` + 标题 + 确定 + 单 `CupertinoPicker`（`textOnSheet`、`selectionOverlay: primary α0.12`、可选 `fieldFill` 内框）。  
   间隔调用该 API；用量可逐步迁入或先只让间隔对齐视觉约定。

2. **间隔数据**  
   保持现有分钟列表与确认回写 `_intervalMinutes`；仅换壳。

3. **时间**  
   组合既有 `showHomeHistoryDatePickerSheet` + `showHomeHistoryTimePickerSheet`（先选日再选时分，或一行两入口）；合并为 `DateTime` 写回 `_lastAt`，clamp ≤ now。  
   备选：扩一个 dateAndTime 玻璃轮——工作量大，优先组合。

4. **字色/主题**  
   禁止再强制 `Brightness.dark`；跟随 `Theme.brightness` + `AppColor` / glass text 原子。

## Risks / Trade-offs

- [两步选日期+时刻步骤变多] → 可接受；比系统 DatePicker 更一致。  
- [通用原子过度抽象] → 首版只抽单滚轮 Sheet，不做泛型 UI 框架。

## Migration Plan

纯客户端 UI；回滚即恢复 Cupertino popup。

## Open Questions

- （无）
