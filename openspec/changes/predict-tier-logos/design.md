## Context

墙内 Pro 已用网络 `CachedNetworkImage` hero；免费档 `logo` 为空故无图。3h 卡仅标题行文字。资产 `pre_basic.png` 已就位。产品要求免费墙补图，且 3h 最左按档显示 logo，图文垂直居中。

## Goals / Non-Goals

**Goals:**

- 免费墙 hero = `Image.asset(kPredictFreeTierLogoAsset)`。
- 3h：`Row(crossAxisAlignment: center, [logo, Expanded(Column(titleRow, body))])`。
- syncing/免费 → 本地免费图；Pro → 网络 logo，空 URL → 与 `FeatureLogo` 同类占位。
- 共用常量路径，避免两处硬编码漂移。

**Non-Goals:**

- 不改开墙热区、upgrade 图标、付费/试用。
- 不把免费 logo 做成 catalog featureId。
- 不改 Pro 墙 16:10 网络图策略（仅补免费槽）。

## Decisions

1. **资产常量**  
   - `kPredictFreeTierLogoAsset = 'assets/images/pre_basic.png'`（放 `predict_capability_tier.dart` 或邻近 chrome 文件）。

2. **3h logo 尺寸**  
   - 约 40 logical px、圆角裁剪；与标题+正文整体 `center` 对齐（非整卡仅标题行贴 logo）。

3. **Pro 占位**  
   - 复用 `FeatureLogo` 空 URL 占位（色块 + `Icons.auto_awesome`）或等价小部件，保证固定宽高不塌布局。

4. **墙免费图比例**  
   - 可用与 Pro 相近的圆角区域展示 asset（`BoxFit.contain`/`cover` 择一，避免拉伸变形）；不强制与 Pro 同为网络缓存。

## Risks / Trade-offs

- [Pro URL 加载慢] → 占位先占位再替换，或直接 CachedNetworkImage error→占位。  
- [syncing 用免费图] → 短暂「看起来像免费」；产品已接受。

## Migration Plan

- 纯 UI；回滚去掉 logo 槽即可。

## Open Questions

- （无）syncing=免费图、Pro 空 URL=占位、新 change 已锁定。
