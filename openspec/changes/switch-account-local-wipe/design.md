## Context

切换账号 `finally` 已清 session、`deviceNo`、`signInChannel`、`feed.clearCache()`（含 `HomeHistoryStore.clearAll`），并已用宿主 `hostContext` + `ProviderContainer` 跳转登录。仍缺：历史进程内存、`homeHistory` 状态、宝宝 prefs 画像、头像本地副本与相关 Provider invalidate。基线要求切换账号**不得**清除凭据历史 store。

## Goals / Non-Goals

**Goals:**

- 单一 wipe 入口，切换账号与注销共用（顺序稳定、可测）。
- 清干净：会话侧、宝宝 ID、宝宝画像 prefs、宝宝头像、喂养历史磁盘 + 内存 + notifier 状态；invalidate 宝宝展示相关 Provider。
- 跳转登录继续走宿主 context / container（Sheet dispose 安全）。

**Non-Goals:**

- 不清除凭据历史 store（基线禁止）。
- 不强制未登录离开 `/settings`（guestAllowed 不变）。
- 不扩大为清 UCG 相册草稿、主题、事件备注 LRU、历史媒体目录（除非已是 wipe 自然副作用；本变更不新增「清媒体」入口）。
- 不改网关注销/登出 HTTP 契约。

## Decisions

1. **抽 `wipeAccountLocalState(container)`（名可微调）**  
   接受 `ProviderContainer`（或 dynamic ref），供 Sheet 在 pop 后调用。  
   理由：与已落地的 host/container 跳转一致；避免 dispose 的 `WidgetRef`。

2. **清 deviceNo 前快照**  
   先读当前 `deviceNo`（及若易得的 babyId），再 `clearLocal`；用快照删 `pangbao_baby_profile_$dn` 与 `BabyAvatarLocalStore.clearAvatar(babyId)`。  
   备选：扫 prefs 前缀全删——更狠但误伤多账号设备上其他宝宝档；优先「当前 dn + 已知 babyId」，若 babyId 未知可扫 `pangbao_baby_profile_` / `baby_avatar_local_v1_` 前缀（实现时选一，推荐当前 dn + 可选前缀兜底）。

3. **历史内存**  
   `await feed.clearCache()` 后：`HomeHistoryMemoryCache.clear()`，并对 `homeHistoryProvider` 置空态（未登录 `refreshFromRemote` 或新增 notifier `clearForSignOut()`）。  
   不在切号路径再打需鉴权的远端历史 HTTP。

4. **Provider invalidate**  
   至少 `settingsBabyProvider`；若存在 `babyAvatar*` FutureProvider 一并 invalidate。预测 range 已 listen session → `clear()`，wipe 内可不重复，可选显式 clear。

5. **调用顺序（建议）**  
   transports release →（快照 dn/babyId）→ session.signOut → wipe 本地宝宝/历史/channel/deviceNo → invalidate → `host.go('/login')`。  
   auth `signOut` HTTP 仍可放 try；wipe 放 finally，保证失败也擦本地。

## Risks / Trade-offs

- [扫 prefs 前缀误删同机其他宝宝档] → 优先只删当前 dn；前缀扫仅作可选兜底并写进注释。  
- [wipe 与 widget 同步竞态] → transports 已 release；可选再推空 widget（非本变更必须）。  
- [注销仍 refreshFromRemote] → 未登录路径会清内存；与 wipe 重叠可接受，可改为只调 wipe。

## Migration Plan

纯客户端；无数据迁移。回滚即去掉 wipe 扩展步骤。

## Open Questions

- （无；凭据历史保留已由基线锁定）
