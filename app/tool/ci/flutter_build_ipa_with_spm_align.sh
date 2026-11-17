#!/usr/bin/env bash
# 可靠 IPA：flutter config-only → align SPM → xcodebuild archive → exportArchive。
# 不用 PATH 包装 xcodebuild：Flutter / CI 常调绝对路径，包装不会执行。
set -euo pipefail

cd "$(dirname "$0")/../.."

EXPORT_OPTIONS_PLIST=""
BUILD_NAME=""
BUILD_NUMBER=""
DART_DEFINES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --export-options-plist)
      EXPORT_OPTIONS_PLIST="${2:-}"
      shift 2
      ;;
    --build-name)
      BUILD_NAME="${2:-}"
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER="${2:-}"
      shift 2
      ;;
    --release)
      # 始终 Release archive
      shift
      ;;
    --dart-define=*)
      DART_DEFINES+=("$1")
      shift
      ;;
    --dart-define)
      DART_DEFINES+=("--dart-define=${2:-}")
      shift 2
      ;;
    *)
      echo "flutter_build_ipa_with_spm_align: 未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$EXPORT_OPTIONS_PLIST" || ! -f "$EXPORT_OPTIONS_PLIST" ]]; then
  echo "flutter_build_ipa_with_spm_align: 需要有效的 --export-options-plist" >&2
  exit 2
fi

echo "[IPA] 1/5 flutter build ios --config-only (写入 Generated.xcconfig / SPM)"
config_args=(flutter build ios --config-only --release --no-codesign)
if [[ -n "$BUILD_NAME" ]]; then
  config_args+=(--build-name "$BUILD_NAME")
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  config_args+=(--build-number "$BUILD_NUMBER")
fi
if [[ ${#DART_DEFINES[@]} -gt 0 ]]; then
  config_args+=("${DART_DEFINES[@]}")
fi
"${config_args[@]}"

# config-only 可能改写工程；补回 Widget SPM 依赖与 Align Build Phase
if [[ -f tool/ci/ensure_pangbao_widget_target.rb ]]; then
  echo "[IPA] 2/5 ensure_pangbao_widget_target (config-only 后补回 Extension)"
  export IOS_WIDGET_BUNDLE_ID="${IOS_WIDGET_BUNDLE_ID:-${IOS_BUNDLE_ID:-}.widget}"
  ruby tool/ci/remove_pangbao_widget_home_widget_pod.rb || true
  ruby tool/ci/ensure_pangbao_widget_target.rb
else
  echo "[IPA] 2/5 skip ensure_pangbao_widget_target"
fi

echo "[IPA] 3/5 align_spm_ios_platforms (抬消费方 Package.swift，须在 archive 正前)"
bash tool/ci/align_spm_ios_platforms.sh

ARCHIVE_DIR="build/ios/archive"
IPA_DIR="build/ios/ipa"
mkdir -p "$ARCHIVE_DIR" "$IPA_DIR"
ARCHIVE_PATH="$ARCHIVE_DIR/Runner.xcarchive"
rm -rf "$ARCHIVE_PATH"

if [[ -d ios/Runner.xcworkspace ]]; then
  xcode_proj_args=(-workspace ios/Runner.xcworkspace)
else
  xcode_proj_args=(-project ios/Runner.xcodeproj)
fi

XCODEBUILD="$(xcrun -f xcodebuild)"

echo "[IPA] 4/5 $XCODEBUILD archive → $ARCHIVE_PATH"
"$XCODEBUILD" "${xcode_proj_args[@]}" \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  CODE_SIGN_STYLE=Manual

echo "[IPA] 5/5 exportArchive → $IPA_DIR"
"$XCODEBUILD" -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$IPA_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

ipa="$(find "$IPA_DIR" -maxdepth 2 -name '*.ipa' | head -n 1 || true)"
if [[ -z "$ipa" ]]; then
  echo "flutter_build_ipa_with_spm_align: export 后未找到 .ipa" >&2
  exit 1
fi
echo "[IPA] OK: $ipa"
