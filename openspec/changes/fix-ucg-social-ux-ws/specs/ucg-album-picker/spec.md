## ADDED Requirements

### Requirement: Album picker selection SHALL update cells incrementally

On the native full-screen album picker grid, toggling selection on one asset MUST update only that cell's selection chrome (badge, disabled overlay on other cells if mode changes) and MUST NOT rebuild the entire grid in a way that restarts all thumbnail `FutureBuilder`s or causes a full-screen flash.

原生全屏相册网格中，选中/取消选中某一资源时，必须仅局部更新该格及因互斥规则受影响的格的选中态，不得重建整表导致缩略图 Future 全部重跑或全屏闪一下。

#### Scenario: 点选单张不闪全屏

- **WHEN** 用户在相册网格中点击某一缩略图的选中角标
- **THEN** UI SHALL 即时更新该格选中态与顶部计数文案
- **AND** 其他未受影响格子的缩略图 SHALL NOT 重新加载或闪烁

#### Scenario: 进入 photo 模式仅禁用视频格

- **WHEN** 用户首次选中一张图片进入 photo 模式
- **THEN** 视频格 SHALL 显示 disabled 遮罩
- **AND** 已加载的图片缩略图格 SHALL 保持原有图像缓存不重绘

#### Scenario: 滚动位置保持

- **WHEN** 用户在中部滚动位置切换选中状态
- **THEN** 列表滚动偏移 SHALL 保持不变
- **AND** SHALL NOT 跳回顶部
