## MODIFIED Requirements

### Requirement: Client SHALL hash final prepared media bytes before upload

The Flutter client MUST compute SHA-256 (hex lowercase, 64 characters) on the final prepared bytes immediately after `ucgCompressImageBytes` or video normalize (via `ucgUploadLocalVideo`) and before any upload or resolve call. For **images**, the client MUST attach `transform_version` `"v1"`. For **native normalized video**, the client MUST attach `transform_version` `"v2"`. For **Web raw video** pending server transcode, the client MUST attach `transform_version` `"v1"`.

客户端 MUST 在图片压缩或视频 normalize 完成后、上传/resolve 前对 prepared bytes 计算 SHA-256。图片 MUST 使用 `transform_version` `"v1"`；原生 normalize 后的视频 MUST 使用 `"v2"`；Web 直传视频 MUST 使用 `"v1"`。

#### Scenario: 图片上传前哈希

- **WHEN** 用户经任意图片入口完成 pick 且 `ucgUploadBytes` 已执行 `ucgCompressImageBytes`
- **THEN** Client SHALL 对压缩后 bytes 计算 SHA-256
- **AND** SHALL 以 `transform_version` `"v1"` 调用 resolve

#### Scenario: 原生 normalize 视频上传前哈希

- **WHEN** 用户上传本地视频且 `ucgUploadLocalVideo` 已完成 native ffmpeg normalize
- **THEN** Client SHALL 对 normalized bytes 计算 SHA-256
- **AND** SHALL 以 `transform_version` `"v2"` 调用 resolve

#### Scenario: Web 视频直传哈希

- **WHEN** Web 用户上传本地视频且未经客户端 normalize
- **THEN** Client SHALL 对 raw prepared bytes 计算 SHA-256
- **AND** SHALL 以 `transform_version` `"v1"` 调用 resolve

#### Scenario: 相同 prepared bytes 跨用户 dedup

- **WHEN** 两名用户上传产生 bitwise 相同的 prepared bytes 与相同 `transform_version`
- **THEN** resolve SHALL 对第二名用户返回 hit
- **AND** 第二名用户 SHALL NOT 再次 PUT OSS
