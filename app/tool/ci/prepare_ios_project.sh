#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

python3 <<'PY'
from pathlib import Path
import os
import re
import sys

path = Path('pubspec.yaml')
text = path.read_text(encoding='utf-8')
original = text


def yaml_single_quoted(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"

wechat_app_id = os.getenv('WECHAT_APP_ID', '').strip()
wechat_universal_link = os.getenv('WECHAT_UNIVERSAL_LINK', '').strip()

if wechat_app_id:
    text, count = re.subn(
        r'(^\s*app_id:\s*).*$' ,
        lambda match: f"{match.group(1)}{yaml_single_quoted(wechat_app_id)}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if count != 1:
        sys.exit('未在 pubspec.yaml 中找到 fluwx.app_id 配置')

if wechat_universal_link:
    text, count = re.subn(
        r'(^\s*universal_link:\s*).*$' ,
        lambda match: f"{match.group(1)}{yaml_single_quoted(wechat_universal_link)}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if count != 1:
        sys.exit('未在 pubspec.yaml 中找到 fluwx.ios.universal_link 配置')

if text != original:
    path.write_text(text, encoding='utf-8')
PY

plist="ios/Runner/Info.plist"
if [[ ! -f "$plist" ]]; then
  echo "缺少 $plist，请先生成 iOS 工程" >&2
  exit 1
fi

python3 <<'PY'
from pathlib import Path
import os
import plistlib

plist_path = Path('ios/Runner/Info.plist')
with plist_path.open('rb') as file:
    info = plistlib.load(file)

info['NSMicrophoneUsageDescription'] = os.getenv(
    'IOS_MICROPHONE_USAGE_DESCRIPTION',
    '需要麦克风权限以支持语音输入与录音',
)
info['NSSpeechRecognitionUsageDescription'] = os.getenv(
    'IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION',
    '需要语音识别权限以将语音转换为文字',
)

display_name = os.getenv('IOS_APP_DISPLAY_NAME', '').strip()
if display_name:
    info['CFBundleDisplayName'] = display_name

with plist_path.open('wb') as file:
    plistlib.dump(info, file)
PY
