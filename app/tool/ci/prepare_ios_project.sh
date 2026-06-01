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

if wechat_universal_link:
    if '*' in wechat_universal_link:
        if wechat_universal_link.endswith('*') and wechat_universal_link.count('*') == 1:
            wechat_universal_link = wechat_universal_link[:-1]
            print('warning: WECHAT_UNIVERSAL_LINK 含末尾 *，已自动归一化', file=sys.stderr)
        else:
            sys.exit('WECHAT_UNIVERSAL_LINK 不能包含 *，请填写微信开放平台登记的完整 https 前缀路径')
    if not wechat_universal_link.startswith('https://'):
        sys.exit('WECHAT_UNIVERSAL_LINK 必须为 https URL')

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

# 出口合规声明：
# false 表示仅使用苹果系统提供或豁免范围内加密，可在多数场景下跳过 App Store Connect 手工出口合规问答。
# true 表示使用非豁免加密，仍需在 App Store Connect 完成相应合规信息。
uses_non_exempt = os.getenv('IOS_USES_NON_EXEMPT_ENCRYPTION', 'false').strip().lower()
info['ITSAppUsesNonExemptEncryption'] = uses_non_exempt in {'1', 'true', 'yes', 'y', 'on'}

display_name = os.getenv('IOS_APP_DISPLAY_NAME', '').strip()
if display_name:
    info['CFBundleDisplayName'] = display_name

with plist_path.open('wb') as file:
    plistlib.dump(info, file)
PY

python3 <<'PY'
from pathlib import Path
import os
import re

target = os.getenv('IOS_DEPLOYMENT_TARGET', '13.0').strip() or '13.0'
podfile = Path('ios/Podfile')
if not podfile.exists():
    raise SystemExit('缺少 ios/Podfile，请先生成 iOS 工程')

text = podfile.read_text(encoding='utf-8')
original = text

platform_line = f"platform :ios, '{target}'"
if re.search(r'^\s*#?\s*platform :ios,', text, flags=re.MULTILINE):
    text = re.sub(
        r'^\s*#?\s*platform :ios,\s*[\'"][^\'"]+[\'"]',
        platform_line,
        text,
        count=1,
        flags=re.MULTILINE,
    )
else:
    insert_at = text.find("ENV['COCOAPODS_DISABLE_STATS']")
    if insert_at == -1:
        text = platform_line + '\n\n' + text
    else:
        line_end = text.find('\n', insert_at)
        text = text[: line_end + 1] + '\n' + platform_line + '\n' + text[line_end + 1 :]

deployment_snippet = f"""      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '{target}'
      end"""

if 'IPHONEOS_DEPLOYMENT_TARGET' not in text and 'post_install do |installer|' in text:
    text = text.replace(
        'flutter_additional_ios_build_settings(target)',
        'flutter_additional_ios_build_settings(target)\n' + deployment_snippet,
        1,
    )

if text != original:
    podfile.write_text(text, encoding='utf-8')
    print(f'Patched Podfile: iOS deployment target {target}')
else:
    print(f'Podfile already targets iOS {target}')
PY
