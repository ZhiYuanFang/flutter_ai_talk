#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

bash tool/ci/vendor_wechat_opensdk.sh

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
import sys

DEFAULT_MICROPHONE = (
    '胖宝需要访问您的麦克风，以便将您说出的育儿记录（例如「宝宝刚刚喝了 120ml 奶」）'
    '转换为文字并保存。麦克风仅用于语音输入，不会在后台录音或用于广告。'
)
DEFAULT_SPEECH = (
    '胖宝需要语音识别权限，以便将您说出的育儿记录（例如「宝宝刚刚喝了 120ml 奶」）'
    '转换为文字并保存。'
)
DEFAULT_PHOTO_LIBRARY = (
    '胖宝需要访问您的相册，以便您在社区发帖时从相册选择图片或视频。'
)
DEFAULT_CAMERA = (
    '胖宝需要访问您的相机，以便您在社区发帖时拍摄照片或视频。'
)


def usage_description(env_name: str, default: str) -> str:
    raw = os.getenv(env_name)
    if raw is None:
        return default
    stripped = raw.strip()
    return stripped if stripped else default


plist_path = Path('ios/Runner/Info.plist')
with plist_path.open('rb') as file:
    info = plistlib.load(file)

info['NSMicrophoneUsageDescription'] = usage_description(
    'IOS_MICROPHONE_USAGE_DESCRIPTION',
    DEFAULT_MICROPHONE,
)
info['NSSpeechRecognitionUsageDescription'] = usage_description(
    'IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION',
    DEFAULT_SPEECH,
)
info['NSPhotoLibraryUsageDescription'] = usage_description(
    'IOS_PHOTO_LIBRARY_USAGE_DESCRIPTION',
    DEFAULT_PHOTO_LIBRARY,
)
info['NSCameraUsageDescription'] = usage_description(
    'IOS_CAMERA_USAGE_DESCRIPTION',
    DEFAULT_CAMERA,
)

# 出口合规声明：
# false 表示仅使用苹果系统提供或豁免范围内加密，可在多数场景下跳过 App Store Connect 手工出口合规问答。
# true 表示使用非豁免加密，仍需在 App Store Connect 完成相应合规信息。
uses_non_exempt = os.getenv('IOS_USES_NON_EXEMPT_ENCRYPTION', 'false').strip().lower()
info['ITSAppUsesNonExemptEncryption'] = uses_non_exempt in {'1', 'true', 'yes', 'y', 'on'}

DEFAULT_BUNDLE_DISPLAY_NAME = '胖宝'
display_name = os.getenv('IOS_APP_DISPLAY_NAME', '').strip()
bundle_display_name = display_name or DEFAULT_BUNDLE_DISPLAY_NAME
if display_name:
    info['CFBundleDisplayName'] = display_name

# App Store「语言」标签来自 IPA bundle 本地化声明（非 ASC 商品描述语言）。
info['CFBundleDevelopmentRegion'] = 'zh-Hans'
info['CFBundleLocalizations'] = ['zh-Hans']

# 小组件点击 widgetURL(pangbao://home) 需在主 App 注册 URL Scheme。
url_types = info.get('CFBundleURLTypes')
if not isinstance(url_types, list):
    url_types = []
has_pangbao = any(
    isinstance(item, dict)
    and isinstance(item.get('CFBundleURLSchemes'), list)
    and 'pangbao' in item.get('CFBundleURLSchemes', [])
    for item in url_types
)
if not has_pangbao:
    url_types.append(
        {
            'CFBundleTypeRole': 'Editor',
            'CFBundleURLName': os.getenv('IOS_BUNDLE_ID', 'com.fzy.pangbaoApp'),
            'CFBundleURLSchemes': ['pangbao'],
        }
    )
    info['CFBundleURLTypes'] = url_types
    print('Info.plist CFBundleURLTypes: added pangbao:// scheme')
else:
    print('Info.plist CFBundleURLTypes: pangbao scheme already present')

with plist_path.open('wb') as file:
    plistlib.dump(info, file)

lproj_dir = Path('ios/Runner/zh-Hans.lproj')
lproj_dir.mkdir(parents=True, exist_ok=True)
escaped_display = bundle_display_name.replace('\\', '\\\\').replace('"', '\\"')
strings_path = lproj_dir / 'InfoPlist.strings'
strings_path.write_text(
    f'"CFBundleDisplayName" = "{escaped_display}";\n'
    f'"CFBundleName" = "{escaped_display}";\n',
    encoding='utf-8',
)
print(f'InfoPlist.strings zh-Hans: ok ({bundle_display_name})')
print('Info.plist CFBundleDevelopmentRegion: zh-Hans')
print('Info.plist CFBundleLocalizations: [zh-Hans]')

for key in (
    'NSMicrophoneUsageDescription',
    'NSSpeechRecognitionUsageDescription',
    'NSPhotoLibraryUsageDescription',
    'NSCameraUsageDescription',
):
    value = info.get(key, '')
    if not value or not str(value).strip():
        sys.exit(f'Info.plist key {key} is missing or empty')
    print(f'Info.plist {key}: ok ({len(str(value))} chars)')
PY

python3 <<'PY'
from pathlib import Path
import plistlib

entitlements_path = Path('ios/Runner/Runner.entitlements')
if not entitlements_path.parent.exists():
    print('skip: ios/Runner 不存在，跳过 Runner.entitlements（flutter create . --platforms=ios 后再执行）')
else:
    data = {}
    if entitlements_path.exists():
        with entitlements_path.open('rb') as file:
            data = plistlib.load(file)
    apple_signin = data.get('com.apple.developer.applesignin')
    if not isinstance(apple_signin, list) or 'Default' not in apple_signin:
        data['com.apple.developer.applesignin'] = ['Default']
        entitlements_path.parent.mkdir(parents=True, exist_ok=True)
        with entitlements_path.open('wb') as file:
            plistlib.dump(data, file)
        print('Patched Runner.entitlements: Sign in with Apple enabled')
    else:
        print('Runner.entitlements already has Sign in with Apple')

    widget_group = 'group.com.fzy.pangbao.widget'
    app_groups = data.get('com.apple.security.application-groups')
    if not isinstance(app_groups, list):
        app_groups = []
    if widget_group not in app_groups:
        app_groups.append(widget_group)
        data['com.apple.security.application-groups'] = app_groups
        with entitlements_path.open('wb') as file:
            plistlib.dump(data, file)
        print(f'Patched Runner.entitlements: App Group {widget_group}')
    else:
        print(f'Runner.entitlements already has App Group {widget_group}')
PY

python3 <<'PY'
from pathlib import Path
import os
import re

target = os.getenv('IOS_DEPLOYMENT_TARGET', '14.0').strip() or '14.0'
podfile = Path('ios/Podfile')
if not podfile.exists():
    # 仓库可能只提交了部分 ios/（含 xcodeproj 但无 Podfile）；CI 亦不会在 xcodeproj 存在时再 flutter create。
    podfile.parent.mkdir(parents=True, exist_ok=True)
    podfile.write_text(
        """# Uncomment this line to define a global platform for your project
# platform :ios, '14.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!

  # Local vendored WeChat OpenSDK (fluwx); avoids CocoaPods downloading from dldir1.qq.com.
  pod 'WechatOpenSDK-XCFramework', :path => 'Vendor/WechatOpenSDK-XCFramework'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    end
  end
end
""",
        encoding='utf-8',
    )
    print('Created ios/Podfile (Flutter default template)')

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

pod_sign_snippet = """      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      end"""

if 'IPHONEOS_DEPLOYMENT_TARGET' not in text and 'post_install do |installer|' in text:
    text = text.replace(
        'flutter_additional_ios_build_settings(target)',
        'flutter_additional_ios_build_settings(target)\n' + deployment_snippet,
        1,
    )

if 'CODE_SIGNING_ALLOWED' not in text and 'post_install do |installer|' in text:
    text = text.replace(
        'flutter_additional_ios_build_settings(target)',
        'flutter_additional_ios_build_settings(target)\n' + pod_sign_snippet,
        1,
    )

# 移除曾误写入 Podfile 的 embed chmod 块（Ruby 双引号内 $1 会语法错误）
if 'CI_PATCH_CODESIGN_CHMOD' in text and 'Pods-Runner-frameworks.sh' in text:
    text = re.sub(
        r'\n  frameworks_sh = File\.join\(installer\.sandbox\.root[\s\S]*?CI_PATCH_CODESIGN_CHMOD[\s\S]*?\n  end\n  end',
        '',
        text,
        count=1,
    )
    print('Patched Podfile: removed invalid embed-chmod Ruby block')

wechat_pod = "  pod 'WechatOpenSDK-XCFramework', :path => 'Vendor/WechatOpenSDK-XCFramework'"
if 'WechatOpenSDK-XCFramework' not in text and "target 'Runner' do" in text:
    text = text.replace(
        "  use_frameworks!\n\n  flutter_install_all_ios_pods",
        f"  use_frameworks!\n\n{wechat_pod}\n\n  flutter_install_all_ios_pods",
        1,
    )
    print('Patched Podfile: local WechatOpenSDK-XCFramework vendor pod')

if text != original:
    podfile.write_text(text, encoding='utf-8')
    print(f'Patched Podfile: iOS deployment target {target}')
else:
    print(f'Podfile already targets iOS {target}')
PY
