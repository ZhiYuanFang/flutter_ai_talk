## Why

当前 App 中仍有“设备ID / 设备缓存 / deviceNo”等用户可见文案，和产品语义不一致。对家长用户而言，该编码应统一认知为“宝宝ID”，避免暴露设备实现细节与理解负担。

## What Changes

- 将所有用户可见文案中的“设备ID”“设备”“deviceNo”等表达统一为“宝宝ID”或对应的宝宝语义表述。
- 保持接口字段与内部实现命名不变（如请求体 `deviceNo`、Provider 命名等），仅调整用户可见文本与提示语。
- 对绑定页、设置页、错误提示、空状态提示进行一致性走查，确保前台不再出现设备相关表述。

## Capabilities

### New Capabilities
- `user-facing-baby-id-terminology`: 约束 App 用户可见层统一使用“宝宝ID”语义，不展示设备相关术语。

### Modified Capabilities
- （无）

## Impact

- 影响前端展示文案：`app/lib/ui/**` 与少量会向用户透传的提示语（如 repository 抛错文案）。
- 不影响后端 API 协议（`deviceNo` 字段仍保留）。
- 不引入新依赖、不改变数据模型。
