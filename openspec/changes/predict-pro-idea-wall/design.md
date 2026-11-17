## Context

两档墙 Pro 档收集「想法」。Go `predict-pro-idea-hub` 提供 list/submit/like。基线 `openspec/specs/v2.2.1.md`；叠在 `predict-capability-tier-wall` / wall-copy 之上。

## Goals / Non-Goals

**Goals:**

- Catalog 正文不变；卡外脚不变。
- 空态底对齐心跳圆钮；有数据富卡片 + 火赞 + 本人高亮 +「我有更多想法」。
- 独立玻璃 Sheet 作曲；整 Sheet 跟键盘；成功刷新墙。

**Non-Goals:**

- Go/HUB；设置反馈；支付/试用；采纳履约；按热度排序；改墙 dialog 内嵌输入条。

## Decisions

1. **数据**  
   - Repository：list / submit / like / unlike（路径对齐 Go）。  
   - 进 Pro 墙 single-flight 拉 list；失败不挡 catalog。

2. **Pro 卡布局**  
   ```
   logo / title / catalog MD
   ─ empty ─
     [弹性区滚 MD]
     ○ 我有想法（心跳，底对齐）
     具备什么功能，你愿意付费开通
   ─ non-empty ─
     可能扩展包含以下能力
     热度越高越可能被收纳进Pro功能中
     被采纳的意见提供者后续可联系管理者，获取免费开通Pro版1个月的资格
     卡片×N（新在前）：
       {宝宝名}的家长          🔥 likeCount
         ┌ 缩进矩形 text ┐   isMine → accent 高亮
     [我有更多想法]
     具备什么功能，你愿意付费开通
   ─ 卡外 ─
     敬请期待 / 正在使用（不变）
   ```

3. **空态钉底**：卡内 Column：上 `Expanded` 滚 MD，下固定圆钮+小字；禁止圆钮堆在 title 下。心跳对齐 `_HeartbeatLogo` 节奏。

4. **作曲 Sheet（新建 modal，不改墙结构）**  
   - 点圆钮或「我有更多想法」→ `showModalBottomSheet`（或等价）玻璃条。  
   - 默认贴底；根节点 `AnimatedPadding(bottom: viewInsets)`（或等价）使 **整张 Sheet** 上移。  
   - **禁止**居中 `showGlassDialog` 作主路径；**禁止**只给 TextField 加 inset。  
   - Controller 由 Sheet State 持有并 dispose。  
   - 发送 → API → pop → 刷新墙内 list。

5. **点赞**：火标样式；点赞区可切换；乐观更新可选，失败回滚。

6. **本人高亮**：`isMine==true` 时想法矩形（或整卡描边）用档位 accent / `AppColor` 语义高亮。

7. **采纳文案**：仅展示；不调履约 API。

## Risks / Trade-offs

- [Go 未就绪] → 空列表 + 失败提示；tasks 标依赖。  
- [Sheet 与墙双 dialog] → Sheet 用墙 context 弹出，成功后墙仍在并 refresh。

## Open Questions

- （已定）空态小字、采纳仅文案、新在前、独立 Sheet、本人高亮。
