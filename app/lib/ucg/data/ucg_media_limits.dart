/// UCG 媒体大小/时长上限（与 go_ai_talk ucg-service `MaxMediaUploadBytes` 对齐）。
abstract final class UcgMediaLimits {
  /// 服务端硬上限（`oss_upload.go` MaxMediaUploadBytes = 25MB）。
  static const serverMaxBytes = 25 * 1024 * 1024;

  /// 客户端视频目标上限（留余量给 multipart 边界）。
  static const videoMaxBytes = 20 * 1024 * 1024;

  /// 客户端图片压缩目标（单张）。
  static const imageMaxBytes = 10 * 1024 * 1024;

  static const videoMaxDuration = Duration(seconds: 15);
}

/// prepared bytes 哈希管线版本；变更压缩/prepare 算法时 bump（如 v2），旧 blob 不参与跨版本 dedup。
const kUcgMediaTransformVersion = 'v1';
