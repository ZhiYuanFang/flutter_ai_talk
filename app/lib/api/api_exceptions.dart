/// 业务失败：`code != 0`，应 Toast [message]。
class ApiBusinessException implements Exception {
  ApiBusinessException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'ApiBusinessException($code): $message';
}

/// HTTP 层非 200 或网络异常。
class ApiHttpException implements Exception {
  ApiHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiHttpException($statusCode): $body';
}
