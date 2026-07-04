import '../../api/api_client.dart';

/// UCG HTTP 客户端：base path `/ucg/app/api`，分页 query `page` / `pageSize`。
class UcgApiClient {
  UcgApiClient(this._api);

  final ApiClient _api;

  static const basePath = '/ucg/app/api';
  static const v2BasePath = '/ucg/app/api/v2';

  String _path(String suffix) {
    if (suffix.isEmpty) return basePath;
    final s = suffix.startsWith('/') ? suffix : '/$suffix';
    return '$basePath$s';
  }

  String v2Path(String suffix) {
    if (suffix.isEmpty) return v2BasePath;
    final s = suffix.startsWith('/') ? suffix : '/$suffix';
    return '$v2BasePath$s';
  }

  Future<Map<String, dynamic>?> get(
    String path, {
    Map<String, String>? query,
    bool withAuthorization = true,
    Duration? timeout,
    bool v2 = false,
  }) {
    return _api.getEnvelope(
      v2 ? v2Path(path) : _path(path),
      query: query,
      withAuthorization: withAuthorization,
      timeout: timeout,
    );
  }

  Future<Map<String, dynamic>?> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
    bool withAuthorization = true,
    bool v2 = false,
  }) {
    return _api.postJsonEnvelope(
      v2 ? v2Path(path) : _path(path),
      body,
      query: query,
      withAuthorization: withAuthorization,
    );
  }

  Future<Map<String, dynamic>?> put(
    String path,
    Map<String, dynamic> body, {
    bool withAuthorization = true,
  }) {
    return _api.putJsonEnvelope(
      _path(path),
      body,
      withAuthorization: withAuthorization,
    );
  }

  Future<Map<String, dynamic>?> delete(
    String path, {
    bool withAuthorization = true,
  }) {
    return _api.deleteEnvelope(
      _path(path),
      withAuthorization: withAuthorization,
    );
  }

  Future<Map<String, dynamic>?> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String fileName,
    required List<int> bytes,
    bool withAuthorization = true,
  }) {
    return _api.postMultipartEnvelope(
      _path(path),
      fields: fields,
      fileField: fileField,
      fileName: fileName,
      bytes: bytes,
      withAuthorization: withAuthorization,
    );
  }

  static Map<String, String> pageQuery({required int page, required int pageSize}) {
    return {'page': '$page', 'pageSize': '$pageSize'};
  }
}
