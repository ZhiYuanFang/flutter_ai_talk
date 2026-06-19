#!/usr/bin/env bash
# 下载并解压微信 OpenSDK XCFramework 到 ios/Vendor/WechatOpenSDK-XCFramework/
# 当 vendored 目录缺失或需升级版本时运行；正常 CI/本地 pod install 应直接使用已提交的 xcframework。
set -euo pipefail

cd "$(dirname "$0")/../.."

VENDOR_DIR="ios/Vendor/WechatOpenSDK-XCFramework"
XCFRAMEWORK="$VENDOR_DIR/WechatOpenSDK.xcframework"
ZIP_URL="https://dldir1.qq.com/WechatWebDev/opensdk/XCFramework/OpenSDK2.0.5.zip"
TMP_ZIP="ios/Vendor/OpenSDK2.0.5.zip"
TMP_EXTRACT="ios/Vendor/_extract"

if [[ -d "$XCFRAMEWORK" ]]; then
  echo "[vendor_wechat_opensdk] $XCFRAMEWORK already exists, skip download"
  exit 0
fi

mkdir -p "ios/Vendor"
echo "[vendor_wechat_opensdk] Downloading OpenSDK 2.0.5 from $ZIP_URL"
if ! curl -f -L --retry 3 -o "$TMP_ZIP" "$ZIP_URL"; then
  echo "[vendor_wechat_opensdk] Download failed. If you are on CI or overseas network, ensure the vendored xcframework is committed, or use a proxy." >&2
  exit 1
fi

rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"
unzip -q "$TMP_ZIP" -d "$TMP_EXTRACT"
mkdir -p "$VENDOR_DIR"
mv "$TMP_EXTRACT/WechatOpenSDK.xcframework" "$XCFRAMEWORK"
rm -rf "$TMP_EXTRACT" "$TMP_ZIP"
echo "[vendor_wechat_opensdk] Installed $XCFRAMEWORK"
