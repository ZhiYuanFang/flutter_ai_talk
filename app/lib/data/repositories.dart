import 'package:package_info_plus/package_info_plus.dart';

export 'feed_repository.dart';
import 'models.dart';

abstract class AuthRepository {
  Future<void> signInWithWeChat();

  /// 胖宝号（设备号）登录：`POST /device/app/api/device_login`，请求体字段 **`deviceNo`**（lowerCamelCase）。
  Future<void> signInWithDeviceNo(String deviceNo);

  Future<void> signOut();
}

abstract class TrendsRepository {
  Future<List<TrendCatalogItem>> loadCatalog();
  Future<TrendSeries> loadSeries(String eventKey, TrendRange range);
}

enum TrendRange { today, week, month, quarter }

abstract class SettingsRepository {
  Future<BabyProfile> loadBaby();
  Future<void> saveBaby(BabyProfile profile);
}

abstract class VersionRepository {
  Future<VersionInfo?> checkForUpdate(String currentVersion);
}

/// 启动时读取真实包版本（需运行到设备/模拟器）。
Future<String> readPackageVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}
