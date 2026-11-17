## Context

两档墙（`PredictCapabilityTierWallPage`）全屏透明 `Material` 吞点击，虽 `barrierDismissible: true` 仍依赖右上 ✕。Free 文案硬编码短句；Pro 用 catalog `description` 但按纯 `Text`；Pro logo `BoxFit.cover` 横向裁满。底栏 `_FooterButton` 关态仍像按钮。3h 免费后缀旁有 `Icons.upgrade`。Go `feature_def.description` 为 `VARCHAR(512)`，Hub 长 MD 会顶满。

## Goals / Non-Goals

**Goals:**

- 说明向墙：点外关、MD 能力说明、本版不可开通 Pro。
- Free MD 清单 + 行首 emoji；禁算法/亲和等词。
- Pro catalog MD + logo contain；脚「敬请期待」/「正在使用」。
- Free 脚恒「正在使用」。
- 非可点脚非按钮形态。
- 3h 隐藏 upgrade。
- Go `description` → TEXT（同 change，Flutter 后改 Go）。

**Non-Goals:**

- 不做 Pro 支付/试用上线。
- 不做版本切换。
- 不改 3h 整卡开墙。
- 不为 MD 做自定义 Material 图标扩展（用 emoji）。
- 不改 Hub 前端编辑器（仅放宽存储）。

## Decisions

1. **关闭**  
   去掉 ✕；外层背景 `GestureDetector`/`Listener` → `pop`，carousel/卡片区域吸收手势，避免全屏 Material 吞 barrier。

2. **Free MD**  
   客户端常量字符串（raw MD），内容含：智能估算下次、推送提醒、桌面小组件、家庭共享、横向投屏、语音球、多日趋势、小智音箱（措辞「可付费开通小智音箱连接能力」）；每条行首 emoji；**无**「xx能做什么」H2；列表 `ListConfig` 零宽 marker（无 ·）；左对齐滚动。Logo 固定高度约 100、contain，非全宽 16:10。脚标签浅透 accent 底。

3. **Pro MD**  
   `Markdown`/`markdown_widget` 渲染 `pro.description`（空则短兜底）；title/logo 仍 catalog。

4. **Logo**  
   Free/Pro 共用 `AspectRatio(16/10)` + `BoxFit.contain`。

5. **底栏**  
   拆「可点按钮」与「状态标签」；本版仅标签。  
   - Free → 正在使用  
   - Pro unlocked → 正在使用  
   - Pro else → 敬请期待  
   标签：无 InkWell、无描边按钮框；背景透明或极淡；字用档位 accent。

6. **停用开通路径**  
   `resolvePredictTierFooter` / 墙 `_onFooter`：本版不进入 trial/pay；可删或短路为标签态。

7. **3h**  
   `showUpgradeIcon` 恒 false / 删除分支。

8. **Go TEXT**  
   `schema.go` CREATE 用 TEXT；EnsureSchema 幂等 `MODIFY COLUMN description TEXT NOT NULL`；Admin/API 仍 string。

## Risks / Trade-offs

- [全屏点外关误触] → 仅遮罩区 pop，卡片内滚动不关。  
- [emoji 机型差异] → 接受；不做矢量替代。  
- [Hub 仍用单行输入] → 存储已够长；编辑体验另议。  
- [已是 Pro 时 Free 也「正在使用」] → 产品确认：表示底座能力在用、不可切换。

## Migration Plan

1. 发 Flutter（墙 UX）。  
2. 同 change 改 Go schema + 部署 EnsureSchema。  
3. Hub 可逐步写入长 MD。  
回滚：Flutter 还原墙；列类型 TEXT→VARCHAR 一般不必要（TEXT 兼容旧短文）。

## Open Questions

- （无）explore 已锁定。
