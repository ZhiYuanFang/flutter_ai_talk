import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// 本机展示用型号字符串；Web / 失败 / iOS map 未命中返回 null（不 PUT）。
///
/// Android：brand（或 manufacturer）+ model；
/// iOS：**仅** `utsname.machine` → 营销名（如 `iPhone 12` / `iPad Air 2`）；未命中不报。
Future<String?> resolveDeviceModelString() async {
  if (kIsWeb) return null;
  try {
    final plugin = DeviceInfoPlugin();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android(await plugin.androidInfo);
      case TargetPlatform.iOS:
        return _ios(await plugin.iosInfo);
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}

String? _android(AndroidDeviceInfo info) {
  final brand = (info.brand.trim().isNotEmpty
          ? info.brand
          : info.manufacturer)
      .trim();
  final model = info.model.trim();
  if (brand.isEmpty && model.isEmpty) return null;
  if (brand.isEmpty) return _sanitize(model);
  if (model.isEmpty) return _sanitize(brand);
  // model 已含 brand 时不再重复拼
  if (model.toLowerCase().contains(brand.toLowerCase())) {
    return _sanitize(model);
  }
  return _sanitize('$brand $model');
}

String? _ios(IosDeviceInfo info) {
  final machine = info.utsname.machine.trim();
  if (machine.isEmpty) return null;
  // 模拟器常见 x86_64 / arm64 → 不报
  if (machine == 'x86_64' || machine == 'arm64' || machine == 'i386') {
    return null;
  }
  final mapped = _iosMapMachine(machine);
  if (mapped == null || mapped.isEmpty) return null;
  return _sanitize(mapped);
}

/// 硬件码 → 营销名；未知返回 null（本次不上报，保留服务端旧值）。
String? _iosMapMachine(String machine) {
  const map = <String, String>{
    // iPhone
    'iPhone8,1': 'iPhone 6s',
    'iPhone8,2': 'iPhone 6s Plus',
    'iPhone8,4': 'iPhone SE',
    'iPhone9,1': 'iPhone 7',
    'iPhone9,3': 'iPhone 7',
    'iPhone9,2': 'iPhone 7 Plus',
    'iPhone9,4': 'iPhone 7 Plus',
    'iPhone10,1': 'iPhone 8',
    'iPhone10,4': 'iPhone 8',
    'iPhone10,2': 'iPhone 8 Plus',
    'iPhone10,5': 'iPhone 8 Plus',
    'iPhone10,3': 'iPhone X',
    'iPhone10,6': 'iPhone X',
    'iPhone11,2': 'iPhone XS',
    'iPhone11,4': 'iPhone XS Max',
    'iPhone11,6': 'iPhone XS Max',
    'iPhone11,8': 'iPhone XR',
    'iPhone12,1': 'iPhone 11',
    'iPhone12,3': 'iPhone 11 Pro',
    'iPhone12,5': 'iPhone 11 Pro Max',
    'iPhone12,8': 'iPhone SE (2nd generation)',
    'iPhone13,1': 'iPhone 12 mini',
    'iPhone13,2': 'iPhone 12',
    'iPhone13,3': 'iPhone 12 Pro',
    'iPhone13,4': 'iPhone 12 Pro Max',
    'iPhone14,4': 'iPhone 13 mini',
    'iPhone14,5': 'iPhone 13',
    'iPhone14,2': 'iPhone 13 Pro',
    'iPhone14,3': 'iPhone 13 Pro Max',
    'iPhone14,6': 'iPhone SE (3rd generation)',
    'iPhone14,7': 'iPhone 14',
    'iPhone14,8': 'iPhone 14 Plus',
    'iPhone15,2': 'iPhone 14 Pro',
    'iPhone15,3': 'iPhone 14 Pro Max',
    'iPhone15,4': 'iPhone 15',
    'iPhone15,5': 'iPhone 15 Plus',
    'iPhone16,1': 'iPhone 15 Pro',
    'iPhone16,2': 'iPhone 15 Pro Max',
    'iPhone17,1': 'iPhone 16 Pro',
    'iPhone17,2': 'iPhone 16 Pro Max',
    'iPhone17,3': 'iPhone 16',
    'iPhone17,4': 'iPhone 16 Plus',
    // iPad Air
    'iPad5,3': 'iPad Air 2',
    'iPad5,4': 'iPad Air 2',
    'iPad11,3': 'iPad Air (3rd generation)',
    'iPad11,4': 'iPad Air (3rd generation)',
    'iPad13,1': 'iPad Air (4th generation)',
    'iPad13,2': 'iPad Air (4th generation)',
    'iPad13,16': 'iPad Air (5th generation)',
    'iPad13,17': 'iPad Air (5th generation)',
    'iPad14,8': 'iPad Air 11-inch (M2)',
    'iPad14,9': 'iPad Air 11-inch (M2)',
    'iPad14,10': 'iPad Air 13-inch (M2)',
    'iPad14,11': 'iPad Air 13-inch (M2)',
    // iPad mini
    'iPad5,1': 'iPad mini 4',
    'iPad5,2': 'iPad mini 4',
    'iPad11,1': 'iPad mini (5th generation)',
    'iPad11,2': 'iPad mini (5th generation)',
    'iPad14,1': 'iPad mini (6th generation)',
    'iPad14,2': 'iPad mini (6th generation)',
    // iPad Pro（常见）
    'iPad8,1': 'iPad Pro 11-inch',
    'iPad8,2': 'iPad Pro 11-inch',
    'iPad8,3': 'iPad Pro 11-inch',
    'iPad8,4': 'iPad Pro 11-inch',
    'iPad8,5': 'iPad Pro 12.9-inch (3rd generation)',
    'iPad8,6': 'iPad Pro 12.9-inch (3rd generation)',
    'iPad8,7': 'iPad Pro 12.9-inch (3rd generation)',
    'iPad8,8': 'iPad Pro 12.9-inch (3rd generation)',
    'iPad13,4': 'iPad Pro 11-inch (3rd generation)',
    'iPad13,5': 'iPad Pro 11-inch (3rd generation)',
    'iPad13,6': 'iPad Pro 11-inch (3rd generation)',
    'iPad13,7': 'iPad Pro 11-inch (3rd generation)',
    'iPad13,8': 'iPad Pro 12.9-inch (5th generation)',
    'iPad13,9': 'iPad Pro 12.9-inch (5th generation)',
    'iPad13,10': 'iPad Pro 12.9-inch (5th generation)',
    'iPad13,11': 'iPad Pro 12.9-inch (5th generation)',
    'iPad14,3': 'iPad Pro 11-inch (4th generation)',
    'iPad14,4': 'iPad Pro 11-inch (4th generation)',
    'iPad14,5': 'iPad Pro 12.9-inch (6th generation)',
    'iPad14,6': 'iPad Pro 12.9-inch (6th generation)',
    // 普通 iPad
    'iPad7,5': 'iPad (6th generation)',
    'iPad7,6': 'iPad (6th generation)',
    'iPad7,11': 'iPad (7th generation)',
    'iPad7,12': 'iPad (7th generation)',
    'iPad11,6': 'iPad (8th generation)',
    'iPad11,7': 'iPad (8th generation)',
    'iPad12,1': 'iPad (9th generation)',
    'iPad12,2': 'iPad (9th generation)',
    'iPad13,18': 'iPad (10th generation)',
    'iPad13,19': 'iPad (10th generation)',
  };
  return map[machine];
}

String? _sanitize(String raw) {
  var t = raw.trim().replaceAll('|', '/');
  if (t.isEmpty) return null;
  if (t.length > 128) t = t.substring(0, 128);
  return t;
}
