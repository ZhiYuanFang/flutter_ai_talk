/// 按 rotation 将编码宽高转为**显示**宽高（90/270 时对调）。
({int width, int height})? ucgVideoDisplaySizeFromCoded({
  required int? width,
  required int? height,
  int? rotation,
}) {
  if (width == null || height == null || width <= 0 || height <= 0) return null;
  var w = width;
  var h = height;
  final r = rotation ?? 0;
  if (r == 90 || r == 270) {
    final t = w;
    w = h;
    h = t;
  }
  return (width: w, height: h);
}

/// 校正 [VideoCompress.getMediaInfo] 返回的 width/height（Android 插件会先 swap 一次）。
({int width, int height})? ucgVideoDisplaySizeFromCompressInfo({
  required int? width,
  required int? height,
  int? orientation,
}) {
  if (width == null || height == null || width <= 0 || height <= 0) return null;
  var w = width;
  var h = height;
  final ori = orientation;
  if (ori == 0 || ori == 180) {
    final t = w;
    w = h;
    h = t;
  }
  return ucgVideoDisplaySizeFromCoded(width: w, height: h, rotation: ori);
}
