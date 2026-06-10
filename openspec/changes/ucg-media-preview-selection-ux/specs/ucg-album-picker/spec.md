## MODIFIED Requirements

### Requirement: Album grid SHALL separate preview tap from selection toggle

In `UcgAlbumPickerScreen`, tapping the thumbnail center MUST open a fullscreen preview without changing selection state. Only tapping the top-right selection badge MUST toggle select/deselect. Unselected items MUST show a hollow selection circle affordance.

相册网格点击缩略图中间须全屏预览且不改变选中态；仅点右上角圆圈切换选中；未选中须显示空心圆。

#### Scenario: 预览不选中
- **WHEN** 用户点击未选中资源的缩略图中间
- **THEN** App SHALL 打开全屏预览
- **AND** 该资源 SHALL 保持未选中

#### Scenario: 圆圈选中
- **WHEN** 用户点击右上角选择圈
- **THEN** App SHALL toggle 选中状态
- **AND** SHALL NOT 打开全屏预览
