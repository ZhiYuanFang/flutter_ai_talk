#!/usr/bin/env python3
"""Validate iOS GitHub Actions secrets before expensive build steps."""

from __future__ import annotations

import base64
import binascii
import os
import plistlib
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def fail(message: str) -> None:
    print(f'::error::{message}', file=sys.stderr)
    sys.exit(1)


def notice(message: str) -> None:
    print(f'::notice::{message}')


def mask(value: str, show: int = 3) -> str:
    value = value.strip()
    if len(value) <= show * 2:
        return '*' * len(value)
    return f'{value[:show]}***{value[-show:]}'


def decode_base64(name: str, raw: str) -> bytes:
    raw = raw.strip()
    if not raw:
        fail(f'[Secret] {name} 为空')
    if 'BEGIN PRIVATE KEY' in raw or 'BEGIN CERTIFICATE' in raw:
        fail(
            f'[Secret] {name} 疑似 PEM 原文，请填入对应二进制文件的 Base64 编码'
            '（.p8 / .p12 / .mobileprovision）'
        )
    try:
        return base64.b64decode(raw, validate=True)
    except binascii.Error:
        fail(f'[Secret] {name} 不是有效的 Base64，请重新编码文件内容')


def validate_team_id() -> None:
    team_id = os.environ.get('IOS_TEAM_ID', '').strip()
    if not re.fullmatch(r'[A-Z0-9]{10}', team_id):
        fail('[Secret] IOS_TEAM_ID 格式应为 10 位大写字母或数字')


def validate_bundle_id() -> None:
    bundle_id = os.environ.get('IOS_BUNDLE_ID', '').strip()
    if '_' in bundle_id:
        fail('[Secret] IOS_BUNDLE_ID 不能包含下划线')
    if '.' not in bundle_id:
        fail('[Secret] IOS_BUNDLE_ID 格式无效，至少应为 com.example.app')


def validate_p12() -> None:
    data = decode_base64(
        'IOS_CERTIFICATE_P12_BASE64',
        os.environ['IOS_CERTIFICATE_P12_BASE64'],
    )
    password = os.environ.get('IOS_CERTIFICATE_PASSWORD', '')
    with tempfile.NamedTemporaryFile(suffix='.p12', delete=False) as tmp:
        tmp.write(data)
        tmp_path = tmp.name
    try:
        proc = subprocess.run(
            [
                'openssl',
                'pkcs12',
                '-in',
                tmp_path,
                '-passin',
                f'pass:{password}',
                '-noout',
            ],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            err = (proc.stderr or proc.stdout or '').strip().lower()
            if 'invalid password' in err or 'mac verify failure' in err:
                fail('[P12] IOS_CERTIFICATE_PASSWORD 错误或 .p12 文件损坏')
            fail(f'[P12] 证书无法解析: {(proc.stderr or proc.stdout or "")[:200]}')
        notice('[Cert] PKCS#12 格式与密码校验通过')
    finally:
        Path(tmp_path).unlink(missing_ok=True)


def read_mobileprovision(data: bytes) -> dict:
    start = data.find(b'<?xml')
    if start == -1:
        fail('[Profile] 描述文件无法解析（缺少 XML plist）')
    end = data.find(b'</plist>', start)
    if end == -1:
        fail('[Profile] 描述文件无法解析（plist 不完整）')
    end += len(b'</plist>')
    try:
        parsed = plistlib.loads(data[start:end])
    except Exception as exc:
        fail(f'[Profile] 描述文件 plist 解析失败: {exc}')
    if not isinstance(parsed, dict):
        fail('[Profile] 描述文件 plist 结构无效')
    return parsed


def profile_bundle_id(profile: dict) -> str:
    entitlements = profile.get('Entitlements', {})
    if not isinstance(entitlements, dict):
        return ''
    app_id = entitlements.get('application-identifier', '')
    if isinstance(app_id, str) and '.' in app_id:
        return app_id.split('.', 1)[1]
    return ''


def profile_team_ids(profile: dict) -> list[str]:
    teams = profile.get('TeamIdentifier', [])
    if isinstance(teams, str):
        return [teams]
    if isinstance(teams, list):
        return [str(item) for item in teams]
    return []


def profile_has_devices(profile: dict) -> bool:
    devices = profile.get('ProvisionedDevices')
    return isinstance(devices, list) and len(devices) > 0


def profile_get_task_allow(profile: dict) -> bool:
    entitlements = profile.get('Entitlements', {})
    if not isinstance(entitlements, dict):
        return False
    return bool(entitlements.get('get-task-allow', False))


def parse_profile_expiration(profile: dict) -> datetime | None:
    expiration = profile.get('ExpirationDate')
    if isinstance(expiration, datetime):
        if expiration.tzinfo is None:
            return expiration.replace(tzinfo=timezone.utc)
        return expiration.astimezone(timezone.utc)
    return None


def selected_profile_base64(export_method: str) -> tuple[str, str]:
    mapping = {
        'app-store': 'IOS_MOBILEPROVISION_APPSTORE_BASE64',
        'ad-hoc': 'IOS_MOBILEPROVISION_ADHOC_BASE64',
        'development': 'IOS_MOBILEPROVISION_DEVELOPMENT_BASE64',
    }
    secret_name = mapping.get(export_method, '')
    if not secret_name:
        fail(f'[Profile] 未知 export_method: {export_method}')

    value = os.environ.get(secret_name, '').strip()
    if value:
        return secret_name, value

    fallback = os.environ.get('IOS_MOBILEPROVISION_BASE64', '').strip()
    if fallback:
        notice(f'[Profile] 未配置 {secret_name}，使用 IOS_MOBILEPROVISION_BASE64 回退校验')
        return 'IOS_MOBILEPROVISION_BASE64', fallback

    fail(f'[Profile] 缺少描述文件 Secret：{secret_name}（或 IOS_MOBILEPROVISION_BASE64）')
    raise AssertionError('unreachable')


def validate_profile(export_method: str) -> None:
    secret_name, raw = selected_profile_base64(export_method)
    data = decode_base64(secret_name, raw)
    profile = read_mobileprovision(data)

    expected_bundle_id = os.environ.get('IOS_BUNDLE_ID', '').strip()
    expected_team_id = os.environ.get('IOS_TEAM_ID', '').strip()
    actual_bundle_id = profile_bundle_id(profile)
    actual_team_ids = profile_team_ids(profile)
    profile_name = str(profile.get('Name', 'unknown'))
    expiration = parse_profile_expiration(profile)

    if actual_bundle_id != expected_bundle_id:
        fail(
            '[Profile] Bundle ID 不匹配 — '
            f'描述文件={actual_bundle_id or "(无法解析)"} '
            f'Secret IOS_BUNDLE_ID={expected_bundle_id}'
        )

    if expected_team_id not in actual_team_ids:
        fail(
            '[Profile] Team ID 不匹配 — '
            f'描述文件 TeamIdentifier={",".join(actual_team_ids) or "(空)"} '
            f'Secret IOS_TEAM_ID={expected_team_id}'
        )

    if expiration is not None and expiration < datetime.now(timezone.utc):
        fail(
            f'[Profile] 描述文件已过期 — name={profile_name} '
            f'ExpirationDate={expiration.date().isoformat()}'
        )

    has_devices = profile_has_devices(profile)
    get_task_allow = profile_get_task_allow(profile)
    if export_method == 'app-store':
        if has_devices:
            fail(
                '[Profile] testflight/appstore 需要 App Store 描述文件，'
                '当前描述文件包含 ProvisionedDevices（疑似 development/ad-hoc）'
            )
    elif export_method == 'ad-hoc':
        if not has_devices:
            fail(
                '[Profile] ad-hoc 需要 Ad Hoc 描述文件，'
                '当前描述文件不包含 ProvisionedDevices（疑似 app-store）'
            )
        if get_task_allow:
            fail('[Profile] ad-hoc 描述文件不得为 development（get-task-allow=true）')
    elif export_method == 'development':
        if not has_devices or not get_task_allow:
            fail('[Profile] development 导出需要 iOS App Development 描述文件')

    expiry_text = expiration.date().isoformat() if expiration else 'unknown'
    notice(
        f'[Profile] 校验通过 name={profile_name} bundle={actual_bundle_id} '
        f'team={expected_team_id} expires={expiry_text}'
    )


def validate_asc_formats() -> None:
    key_id = os.environ.get('APP_STORE_CONNECT_KEY_ID', '').strip()
    issuer_id = os.environ.get('APP_STORE_CONNECT_ISSUER_ID', '').strip()
    p8_raw = os.environ.get('APP_STORE_CONNECT_API_KEY_P8_BASE64', '').strip()

    if key_id.startswith('AuthKey_') or key_id.endswith('.p8'):
        fail(
            '[ASC] APP_STORE_CONNECT_KEY_ID 应只填 Key ID（10 位），'
            '不要包含 AuthKey_ 或 .p8'
        )
    if not re.fullmatch(r'[A-Z0-9]{10}', key_id):
        fail('[ASC] APP_STORE_CONNECT_KEY_ID 格式应为 10 位字母数字')

    uuid_pattern = (
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    )
    if not re.fullmatch(uuid_pattern, issuer_id):
        fail('[ASC] APP_STORE_CONNECT_ISSUER_ID 应为 UUID 格式')

    p8_bytes = decode_base64('APP_STORE_CONNECT_API_KEY_P8_BASE64', p8_raw)
    p8_text = p8_bytes.decode('utf-8', errors='replace')
    if 'BEGIN PRIVATE KEY' not in p8_text:
        fail(
            '[ASC] APP_STORE_CONNECT_API_KEY_P8_BASE64 解码后不是有效的 .p8 私钥'
            '（缺少 BEGIN PRIVATE KEY）'
        )

    notice(
        f'[ASC] 格式校验通过 key_id={mask(key_id)} issuer={mask(issuer_id, 4)}'
    )


def main() -> None:
    export_method = os.environ.get('EFFECTIVE_EXPORT_METHOD', '').strip()
    target_channel = os.environ.get('TARGET_CHANNEL', '').strip()
    if not export_method:
        fail('[Config] 缺少环境变量 EFFECTIVE_EXPORT_METHOD')

    validate_team_id()
    validate_bundle_id()
    validate_p12()
    validate_profile(export_method)

    if target_channel in {'testflight', 'appstore'}:
        validate_asc_formats()


if __name__ == '__main__':
    main()
