## Why

在“绑定宝宝-输入宝宝ID”区域，用户当前缺少获取宝宝ID的指引，首次使用时不清楚应从哪里找到该编号。增加一行辅助说明可以降低理解成本并减少误操作。

## What Changes

- 在绑定宝宝页面“输入宝宝ID”输入框下方新增一行小字说明：从你的家人那查看宝宝信息，复制宝宝id输入。
- 仅调整前端展示与文案，不改变绑定流程、路由与 API 请求结构。
- 保持现有页面视觉风格，新增说明作为次级提示信息。

## Capabilities

### New Capabilities
- `baby-bind-id-helper-text`: 规范绑定宝宝页面在输入宝宝ID区域展示获取来源提示文案。

### Modified Capabilities
- （无）

## Impact

- 影响文件：`app/lib/ui/baby_bind_screen.dart`。
- 影响范围：绑定宝宝模式的输入区域文案展示。
- 不涉及后端接口、数据模型与依赖变更。
