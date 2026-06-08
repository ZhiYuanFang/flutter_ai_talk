/// 发布入口/相册选择后的 compose 预填媒体。
class UcgComposeInitialMedia {
  const UcgComposeInitialMedia({
    this.imageKeys = const [],
    this.videoKey,
  });

  final List<String> imageKeys;
  final String? videoKey;

  bool get isEmpty =>
      imageKeys.isEmpty && (videoKey == null || videoKey!.isEmpty);
}
