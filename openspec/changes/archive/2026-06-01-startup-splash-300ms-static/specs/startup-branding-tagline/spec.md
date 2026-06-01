## MODIFIED Requirements

### Requirement: Startup overlay shows tagline below logo

The cold-start Flutter branding overlay SHALL display the tagline「最懂你的胖宝」directly below the static logo, centered horizontally, without pulse animation on the logo. 冷启动 Flutter 品牌遮罩**必须**在**静态** Logo 下方居中展示标语「最懂你的胖宝」，Logo **不得**再使用心跳脉冲动画。

#### Scenario: Tagline visible during branding

- **WHEN** the app shows `StartupBrandingOverlay` after native splash is dismissed
- **THEN** the user sees a static logo and the tagline「最懂你的胖宝」beneath it on the brand background color

### Requirement: Tagline color follows theme primary

The tagline color SHALL use `Theme.of(context).colorScheme.primary` at full opacity in the static final style. 标语颜色**必须**使用当前主题 `ColorScheme.primary` 满不透明终态色，**不得**再通过透明度动画过渡。

#### Scenario: Primary color at display

- **WHEN** the branding overlay is visible
- **THEN** the tagline text uses the current theme primary color at full opacity

## REMOVED Requirements

### Requirement: Tagline reveal completes within 1.5 seconds

**Reason**: 产品要求去掉启动页动画，标语改为静态展示。

**Migration**: 使用固定终态字体大小与字重（与原 Reveal 结束态一致），删除 `StartupTaglineReveal` 及 `kStartupTaglineRevealDuration`。

### Requirement: Tagline fades with overlay

**Reason**: 启动遮罩改为即时移除，不再使用 opacity 淡出动画。

**Migration**: 删除 `AnimatedOpacity` 与 `kStartupBrandingFadeOut`；遮罩与标语随 `_showStartupOverlay = false` 一并移除。

### Requirement: Startup timing unchanged

**Reason**: 最短展示时长由 2400ms 调整为 300ms，与 `startup-splash-static-300ms` 变更一致。

**Migration**: 将 `kMinStartupBrandingDisplay` 设为 `Duration(milliseconds: 300)`，并更新 `app.dart` 遮罩移除逻辑。
