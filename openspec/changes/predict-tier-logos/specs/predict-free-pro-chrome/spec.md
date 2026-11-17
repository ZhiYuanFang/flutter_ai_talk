## ADDED Requirements

### Requirement: Free tier wall SHALL show local pre_basic logo

When the Free/Pro tier wall shows the Free card, the client MUST render the bundled asset `assets/images/pre_basic.png` as that card’s logo/hero image. The client MUST NOT require a catalog `featureId` or remote URL for the free-tier logo. Pro card network logo behavior from catalog MUST remain when a non-empty http(s) URL is present.

免费档墙 MUST 展示本地 `pre_basic.png`；MUST NOT 依赖 catalog featureId；Pro 有 URL 时仍 MUST 用网络 logo。

#### Scenario: 免费墙出本地图

- **WHEN** 用户在两档墙滑到或停在免费版卡
- **THEN** UI MUST 展示 `assets/images/pre_basic.png`

### Requirement: Next-3-hours card SHALL show tier logo on the leading edge

On the bound「接下来3小时」card, the client MUST show a leading tier logo to the left of the title/body text column, with the logo and text column vertically centered relative to each other (`CrossAxisAlignment.center` or equivalent). Logo selection MUST be：syncing or free suffix → `assets/images/pre_basic.png`；Pro suffix → catalog Pro `logo` when it is a usable http(s) URL；when Pro has no usable logo URL, the client MUST show a fixed-size placeholder icon（MUST NOT leave an empty collapsed gap）.

3h 卡最左 MUST 出档位 logo；syncing/免费 → `pre_basic`；Pro → catalog 图，无 URL → 定尺寸占位；图文 MUST 纵向居中。

#### Scenario: syncing 用免费图

- **WHEN** 3h 档位 chrome 为 syncing
- **THEN** 卡最左侧 MUST 展示 `pre_basic.png`

#### Scenario: 免费档用免费图

- **WHEN** 后缀为「· 免费版」
- **THEN** 卡最左侧 MUST 展示 `pre_basic.png`

#### Scenario: Pro 无 URL 占位

- **WHEN** 后缀为「· Pro版」且 catalog Pro logo 为空或不可用
- **THEN** 卡最左侧 MUST 展示定尺寸占位图标
- **AND** MUST NOT 因缺图导致标题行高度塌陷错位
