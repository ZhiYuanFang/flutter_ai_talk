## 1. 锁屏 UI

- [x] 1.1 从 `BabyLiveActivityWidget` 锁屏视图移除「胖宝」顶栏 HStack；`VStack` 仅按 `items` 堆叠既有行；不改 Island / 行组件语义
- [x] 1.2 清理仅服务顶栏且已无引用的主题色 helper（如 `themePrimaryHex` / `laThemeBrandColor`）；有其它引用则保留

## 2. 文档与核对

- [x] 2.1 更新 `LIVE_ACTIVITY.md`：锁屏不再描述顶栏「胖宝」居中主题色，改为仅 items 纵向列表
- [ ] 2.2 真机确认：锁屏无 App 名顶栏、高度更紧、行样式与 Island 不变
