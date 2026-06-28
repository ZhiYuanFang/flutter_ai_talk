/// compose 视频预览卡片布局（方案 B：竖 2/3×9:16，横全宽×16:9）。
const ucgComposePortraitVideoWidthFraction = 2 / 3;
const ucgComposePortraitVideoAspectRatio = 9 / 16;
const ucgComposeLandscapeVideoAspectRatio = 16 / 9;

bool ucgVideoIsPortrait({int? width, int? height}) {
  if (width != null && height != null && width > 0 && height > 0) {
    return height > width;
  }
  return true;
}

double ucgVideoPreviewAspectRatio({
  int? width,
  int? height,
  required bool isPortrait,
}) {
  if (width != null && height != null && width > 0 && height > 0) {
    return width / height;
  }
  return isPortrait ? ucgComposePortraitVideoAspectRatio : ucgComposeLandscapeVideoAspectRatio;
}

double ucgComposeVideoDisplayWidth(double contentWidth, {required bool isPortrait}) {
  if (isPortrait) return contentWidth * ucgComposePortraitVideoWidthFraction;
  return contentWidth;
}
