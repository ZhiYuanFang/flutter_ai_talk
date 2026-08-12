## 1. 延迟测锚开播

- [x] 1.1 预测向飞入：历史写入后延迟至至少 2 个 post-frame（或等价）再挂载/启动 Overlay 测锚；喂养可保持立即或共享短延迟
- [x] 1.2 开播前锚点稳定检测（连续两帧位移小于阈值）或加强 pop 阶段 `_updateEndFromAnchor`

## 2. 校验

- [x] 2.1 `openspec validate prediction-fly-measure-after-reorder --strict`
- [ ] 2.2 手工：预测页加/改导致换位时，飞入落到新位置卡片 logo；喂养飞入仍正常
