# App Store Connect — App Privacy 问卷（提审前人工填写）

本变更启用 UCG **使用时**精确定位，用于展示动态距离。提审前请在 App Store Connect → App Privacy 更新：

| 数据类型 | 申报 |
|----------|------|
| **Location → Precise Location** | 收集；链接到用户；用途 **App Functionality**（展示 UCG 动态与你的距离）；**非 Tracking**；用户可拒绝且仍可使用 UCG |
| **Contacts** | 不收集（不变） |
| **Data Used to Track You** | 否（不变） |

须与 `resource/public/privacy-policy.html`（网关侧）表述一致：可选 GPS、拒绝不影响核心功能。
