## Context

设置 UI「彩色」= `preset: null` + 自定义 `seed`。浅色自定义曾：

```
seedColor = seed
shellColor = seed   // 满色页底 → BackdropFilter 灌色进玻璃
```

经典：

```
seedColor = 性别主色
shellColor = 白 + seed@0.08
```

仅改 `panelGlass` 近白叠色不够：模糊仍采样满色 shell。须让自定义浅色 **bundle 与经典同构**。

暗壳 `deriveDarkBundle` 亮 accent、浅色 panelGlass 近白配方已部分落地。

## Goals / Non-Goals

**Goals:**

- 自定义浅色（设置「彩色」）与经典：同构近白壳 + seed 染料。
- soft swatch 同样同构（避免遗留路径再分裂）。
- 暗壳非夜空：亮 accent 染料（已有）；夜空常量不动。

**Non-Goals:**

- 不改选色器 UI；不改事件卡 accent 第二步；不新建测试。

## Decisions

### 1. 浅色 tinted helper（经典 / 彩色 / soft swatch 共用）

```
lightTintedBundle(seed):
  seedColor   = seed
  shellColor  = 白 + seed@0.08
  surfaceColor= 白 + seed@0.04
  isDarkShell = false
```

- `classicLightBundle` → `lightTintedBundle(sexPrimary)`
- 自定义浅色 → `lightTintedBundle(seed)`（**不再** `shellColor = seed`）
- `lightSwatchBundle` → `lightTintedBundle(swatch)`

### 2. panelGlass 浅色近白配方保持

近白 base + seed@0.18 / 更白 bottom；与页底同构后 BackdropFilter 采样近白，渐变稳定。

### 3. 暗壳

保持已实现的 `_darkChromeAccentFromSeed`；夜空走固定三色。

## Risks / Trade-offs

- [彩色页底不再「整页一块色」] → 改为经典式淡染近白；产品明确要同构调色，可接受。
- [旧用户已存满色 seed] → 重载后自动变近白壳+同色染料，属预期迁移。

## Migration Plan

- 无持久化字段变更；仅派生公式变。回滚恢复 `shellColor = seed` 即可。

## Open Questions

- 无。
