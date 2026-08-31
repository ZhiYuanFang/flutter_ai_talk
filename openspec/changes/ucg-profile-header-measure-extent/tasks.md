## 1. 测高与占位

- [x] 1.1 壳层增加 measured / placeholder `maxExtent` 状态；去掉主人 `248` 等作为测高后终值
- [x] 1.2 资料卡 `GlobalKey`（或等价）post-frame 测高；阈值合并更新
- [x] 1.3 占位高度保守稳定（可暂用旧常量仅作占位）；重测期间保持上一实测，避免闪回过矮
- [x] 1.4 修复：去掉折叠头内 `OverflowBox(∞)`；改为定宽 Offstage 测高探针
- [x] 1.5 修复：探针 `heightFactor: 1` shrink-wrap + 卡高 sanity，避免 maxExtent 吃满全屏

## 2. 接线与内容变更

- [x] 2.1 `profile` / `wxBound` / owner·viewer 差异 / 邀请异步等变更时调度重测
- [x] 2.2 delegate 传入实测 `expandedHeight`；确认折叠 morph 仍可用

## 3. 验收

- [ ] 3.1 主人含邀请行：展开态完整可见、无底裁；冷启无明显先矮后高闪屏
- [ ] 3.2 邀请 loading→data 或 bio 变高后 maxExtent 跟上且不闪回过矮
- [ ] 3.3 滚动仍可折叠至仅小头像；无 infinite layout；`openspec validate ucg-profile-header-measure-extent --strict`
