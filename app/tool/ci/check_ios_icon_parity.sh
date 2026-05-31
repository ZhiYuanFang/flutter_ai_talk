#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PUBSPEC="pubspec.yaml"
SOURCE_ICON="assets/images/app_icon.png"
APPICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$PUBSPEC" ]]; then
  echo "::error::缺少 $PUBSPEC" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "::error::缺少图标源文件：$SOURCE_ICON" >&2
  echo "::error::修复：请将 Android 主图标放在 $SOURCE_ICON（或同步更新 pubspec.yaml 的 image_path 与 adaptive_icon_foreground）。" >&2
  exit 1
fi

ICON_BLOCK="$(awk '
  BEGIN { in_block=0 }
  /^flutter_launcher_icons:/ { in_block=1; next }
  in_block && /^[^[:space:]]/ { in_block=0 }
  in_block { print }
' "$PUBSPEC")"

if [[ -z "$ICON_BLOCK" ]]; then
  echo "::error::pubspec.yaml 缺少 flutter_launcher_icons 配置块。" >&2
  echo "::error::修复：在 pubspec.yaml 添加 flutter_launcher_icons 配置并启用 ios。" >&2
  exit 1
fi

if ! grep -Eq '^\s*android:\s*true\s*$' <<<"$ICON_BLOCK"; then
  echo "::error::flutter_launcher_icons.android 必须为 true。" >&2
  exit 1
fi

if ! grep -Eq '^\s*ios:\s*true\s*$' <<<"$ICON_BLOCK"; then
  echo "::error::flutter_launcher_icons.ios 必须为 true。" >&2
  echo "::error::修复：将 pubspec.yaml 中 flutter_launcher_icons.ios 设为 true。" >&2
  exit 1
fi

IMAGE_PATH="$(sed -nE 's/^\s*image_path:\s*//p' <<<"$ICON_BLOCK" | head -n1 | tr -d '"' | tr -d "'")"
ANDROID_FG_PATH="$(sed -nE 's/^\s*adaptive_icon_foreground:\s*//p' <<<"$ICON_BLOCK" | head -n1 | tr -d '"' | tr -d "'")"

if [[ -z "$IMAGE_PATH" ]]; then
  echo "::error::flutter_launcher_icons.image_path 不能为空。" >&2
  exit 1
fi

if [[ -z "$ANDROID_FG_PATH" ]]; then
  echo "::error::flutter_launcher_icons.adaptive_icon_foreground 不能为空。" >&2
  exit 1
fi

if [[ "$IMAGE_PATH" != "$ANDROID_FG_PATH" ]]; then
  echo "::error::iOS 与 Android 未使用同源图标：image_path=$IMAGE_PATH, adaptive_icon_foreground=$ANDROID_FG_PATH" >&2
  echo "::error::修复：将 image_path 与 adaptive_icon_foreground 统一为同一路径。" >&2
  exit 1
fi

if [[ "$IMAGE_PATH" != "$SOURCE_ICON" ]]; then
  echo "::warning::当前主图标源不是默认路径 $SOURCE_ICON，而是 $IMAGE_PATH。请确认 Android 与 iOS 仍为同源。"
  SOURCE_ICON="$IMAGE_PATH"
fi

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "::error::配置中的图标源不存在：$SOURCE_ICON" >&2
  exit 1
fi

ICON_INFO="$(python3 - "$SOURCE_ICON" <<'PY'
from pathlib import Path
import sys

icon = Path(sys.argv[1])
data = icon.read_bytes()
if data[:8] != b"\x89PNG\r\n\x1a\n":
    print("ERR:not_png")
    raise SystemExit(0)

width = int.from_bytes(data[16:20], "big")
height = int.from_bytes(data[20:24], "big")
color_type = data[25]
has_alpha = color_type in (4, 6)
print(f"OK:{width}:{height}:{color_type}:{1 if has_alpha else 0}")
PY
)"

if [[ "$ICON_INFO" == ERR:* ]]; then
  echo "::error::图标源必须为 PNG：$SOURCE_ICON" >&2
  exit 1
fi

IFS=':' read -r _ ICON_W ICON_H ICON_COLOR ICON_ALPHA <<<"$ICON_INFO"

echo "[Icon Parity] source=$SOURCE_ICON width=$ICON_W height=$ICON_H color_type=$ICON_COLOR has_alpha=$ICON_ALPHA"

if [[ "$ICON_W" != "$ICON_H" ]]; then
  echo "::error::图标源必须是正方形（当前 ${ICON_W}x${ICON_H}）。" >&2
  exit 1
fi

if (( ICON_W < 512 )); then
  echo "::error::图标分辨率过小（当前 ${ICON_W}x${ICON_H}），至少需要 512x512。" >&2
  exit 1
fi

if (( ICON_W < 1024 )); then
  echo "::warning::建议使用至少 1024x1024 的源图以获得更佳 iOS 显示质量（当前 ${ICON_W}x${ICON_H}）。"
fi

if [[ ! -d "$APPICON_DIR" ]]; then
  echo "::error::缺少 $APPICON_DIR。" >&2
  echo "::error::修复：先执行 flutter pub get && dart run flutter_launcher_icons 重新生成。" >&2
  exit 1
fi

if [[ ! -f "$APPICON_DIR/Contents.json" ]]; then
  echo "::error::缺少 $APPICON_DIR/Contents.json。" >&2
  exit 1
fi

required_icons=(
  "Icon-App-1024x1024@1x.png"
  "Icon-App-60x60@2x.png"
  "Icon-App-60x60@3x.png"
  "Icon-App-76x76@2x.png"
)

missing=()
for f in "${required_icons[@]}"; do
  if [[ ! -f "$APPICON_DIR/$f" ]]; then
    missing+=("$f")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "::error::AppIcon 集不完整，缺少：${missing[*]}" >&2
  echo "::error::修复：执行 flutter pub get && dart run flutter_launcher_icons 后重新提交。" >&2
  exit 1
fi

icon_count=$(find "$APPICON_DIR" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')
echo "[Icon Parity] app_iconset=$APPICON_DIR png_count=$icon_count"
echo "[Icon Parity] check passed"
