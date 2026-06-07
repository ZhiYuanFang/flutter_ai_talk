## ADDED Requirements

### Requirement: ucg-service SHALL expose server-owned image thumbnail URLs in DTOs

The ucg-service MUST centralize CDN URL construction via `BuildCdnURL(objectKey)` and `BuildImageThumbnailURL(objectKey)` using OSS process string `image/auto-orient,1/resize,m_lfit,w_200/quality,q_90/format,jpg`. Image-bearing responses SHALL populate thumbnail fields; video media MUST NOT receive server-generated poster URLs. List-surface avatar enrichment (Feed author, liker grid, follow list, conversation list, chat peer) SHALL expose `avatarThumbnailUrl` (or `peerAvatarThumbnailUrl`) alongside full `avatarUrl` for profile-header-only consumption.

#### Scenario: Feed post image media includes thumbnailUrl
- **WHEN** `GET /feed/recommend` or `/feed/following` returns a post with `mediaKind=image`
- **THEN** each image media item SHALL include `cdnUrl` (full resolution) and `thumbnailUrl` (server-built OSS thumb URL)
- **AND** video media items SHALL include `cdnUrl` only and MUST NOT include `thumbnailUrl` or `thumbKey`

#### Scenario: Profile responses include avatarThumbnailUrl
- **WHEN** `GET /profile/me` or `GET /profile/{wxId}` returns a user with `avatarKey`
- **THEN** response SHALL include `avatarUrl` (full resolution, for profile header/home only) and `avatarThumbnailUrl` built by `BuildImageThumbnailURL`

#### Scenario: List enrichment exposes avatarThumbnailUrl
- **WHEN** Feed posts, liker grids, follow lists, or conversation list items include author/peer avatar enrichment
- **THEN** each enriched user object SHALL include `avatarThumbnailUrl` for list-surface display
- **AND** Client list surfaces MUST consume `avatarThumbnailUrl`, not full `avatarUrl`

#### Scenario: Chat image messages include mediaThumbnailUrl
- **WHEN** `GET /conversations/{id}/messages` returns an image message with `imageKey`
- **THEN** each message SHALL include `mediaCdnUrl` and `mediaThumbnailUrl` for list/bubble display
- **AND** video messages SHALL include `mediaCdnUrl` only without `mediaThumbnailUrl`

#### Scenario: Flutter MUST NOT append client-side OSS for images
- **WHEN** Flutter parses UCG media for list display
- **THEN** Client SHALL use API `thumbnailUrl` / `avatarThumbnailUrl` / `mediaThumbnailUrl` when present
- **AND** Client MUST NOT append `x-oss-process` via `UcgMediaUrl.ossProcessUrl` or equivalent
