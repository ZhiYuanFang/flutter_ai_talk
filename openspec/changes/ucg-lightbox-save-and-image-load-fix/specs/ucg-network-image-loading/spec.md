## ADDED Requirements

### Requirement: CachedNetworkImage loading indicators MUST be mutually exclusive

When `UcgNetworkImage` enables an in-image loading indicator on non-Web platforms (`showLoadingIndicator` true), the client MUST set **exactly one** of `CachedNetworkImage.placeholder` or `CachedNetworkImage.progressIndicatorBuilder` to non-null, and MUST leave the other null. The client MUST NOT pass both non-null (octo_image asserts). Web MAY continue using `Image.network` `loadingBuilder`. Fullscreen lightbox full-resolution remote loads MUST still show a visible loading indicator until the image is ready (baseline lightbox loading behavior unchanged).

非 Web 且开启 loading 时，`UcgNetworkImage` **必须** 只设置 `placeholder` 与 `progressIndicatorBuilder` 之一为非 null，**必须 NOT** 同时非 null。Web 可用 `loadingBuilder`。全屏 lightbox 全分辨率加载 **必须** 仍展示可见 loading。

#### Scenario: lightbox 加载不触发互斥断言

- **WHEN** 用户打开全屏图片 lightbox 加载远程全分辨率图且启用 loading
- **THEN** 客户端 MUST 展示可见 loading 指示
- **AND** MUST NOT 因同时设置 placeholder 与 progressIndicatorBuilder 而抛出 octo_image 断言

#### Scenario: 关闭 loading 时两者皆空

- **WHEN** `showLoadingIndicator` 为 false
- **THEN** 原生 CachedNetworkImage 的 placeholder 与 progressIndicatorBuilder MUST 均为 null
