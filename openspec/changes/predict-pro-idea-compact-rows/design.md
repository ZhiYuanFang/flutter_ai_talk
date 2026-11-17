## Context

`PredictProIdeaPanel` 有数据态目前三行说明 + 家长名行 + 缩进矩形正文。产品要去采纳资格文案、去家长昵称、改紧凑 bullet 行。基线叠在 `predict-pro-idea-wall`；对照 `openspec/specs/v2.2.1.md`。

## Goals / Non-Goals

**Goals:**

- 删除采纳资格小字与家长昵称 UI。
- 每条：`•`（列表 bullet）+ 正文 | 火赞热度，交叉轴居中。
- `isMine` 整行 accent 高亮。

**Non-Goals:**

- 改 API / 排序 / 空态 / Sheet / 支付履约。
- 删除「热度越高…」引导小字。
- 按热度重排。

## Decisions

1. **Bullet**  
   - 使用列表 bullet 字形（如 `•` / `·`），**不是** ASCII `-` 减号；前缀固定、不跟服务端。

2. **行布局**  
   ```
   [•] [Expanded 想法 text]     [🔥 likeCount]
   ```  
   - `Row` + `CrossAxisAlignment.center`；多行正文时热度相对整块垂直居中。  
   - 去掉缩进矩形 `DecoratedBox` 与家长 `authorLabel` 行。

3. **本人高亮**  
   - `isMine`：整行（bullet + 正文，热度可同用 accent）字色/字重跟 accent；非本人用 onGlass / muted。  
   - 可不保留矩形底，避免再占高。

4. **头部文案**  
   - 保留标题 +「热度越高…」；**删除**「被采纳…资格」及其间距。

5. **数据**  
   - 仍映射 `babyName`（兼容）；仅 UI 不展示。

## Risks / Trade-offs

- [去掉矩形后本人高亮仅靠字色] → 产品已选整行 accent；对比度不足时可略加字重。  
- [长文挤压热度] → Expanded 左列 + 右列 `mainAxisSize.min`。

## Open Questions

- （已定）整行 accent；列表 bullet。
