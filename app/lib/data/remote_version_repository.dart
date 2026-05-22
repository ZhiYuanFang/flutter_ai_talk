import '../api/api_client.dart';
import '../api/gateway_absolute_url.dart';
import '../api/gateway_json.dart';
import '../api/api_exceptions.dart';
import '../config/env.dart';
import 'models.dart';
import 'repositories.dart' show VersionRepository;

class RemoteVersionRepository implements VersionRepository {
  RemoteVersionRepository(this._api);

  final ApiClient _api;

  @override
  Future<VersionInfo?> checkForUpdate(String currentVersion) async {
    if (AppEnv.mockNewerVersion) {
      return VersionInfo(
        latestVersion: _bumpVersion(currentVersion),
        releaseNotes: '联调：MOCK_NEWER_VERSION=true',
        androidApkUrl: 'https://example.com/pangbao-latest.apk',
        forceUpdate: false,
      );
    }
    try {
      final data = await _api.getEnvelope(
        '/device/app/api/version/check',
        query: {'currentVersion': currentVersion},
        withAuthorization: false,
      );
      if (data == null) return null;
      final need = data['needUpdate'] as bool? ?? false;
      if (!need) return null;
      final downloadRaw = readGatewayStr(data, 'downloadUrl', 'download_url');
      return VersionInfo(
        latestVersion: data['latestVersion'] as String? ?? '',
        releaseNotes: (data['releaseNotes'] as String?) ?? '',
        androidApkUrl: resolveGatewayAbsoluteUrl(downloadRaw) ?? '',
        forceUpdate: data['forceUpdate'] as bool? ?? false,
      );
    } on ApiBusinessException {
      return null;
    }
  }

  String _bumpVersion(String v) {
    final parts = v.split('.');
    if (parts.isEmpty) return '9.9.9';
    final major = int.tryParse(parts.first) ?? 1;
    return '${major + 1}.0.0';
  }
}
