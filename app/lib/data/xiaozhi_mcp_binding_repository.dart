import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/gateway_json.dart';
import 'xiaozhi_mcp_models.dart';

/// 小智音箱绑定 CRUD（`/device/app/api/xiaozhi-mcp/bindings*`）。
///
/// 失败由 [ApiClient] 记 HTTP 日志；本类 **不得** 打印完整 mcpToken。
class XiaozhiMcpBindingRepository {
  XiaozhiMcpBindingRepository(
    this._api, {
    void Function(String message)? onToastError,
  }) : _onToastError = onToastError ?? ((_) {});

  final ApiClient _api;
  final void Function(String message) _onToastError;

  /// 列出当前用户绑定（脱敏）。
  Future<List<XiaozhiMcpBindingItem>> list() async {
    try {
      final data = await _api.getEnvelope('/device/app/api/xiaozhi-mcp/bindings');
      return envelopeListOrEmpty(data)
          .whereType<Map>()
          .map((e) => XiaozhiMcpBindingItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }

  /// 添加绑定；同 MAC 服务端可 upsert。
  Future<XiaozhiMcpBindingAddResult> add({
    required String mcpToken,
    required String speakerMac,
    required String alias,
  }) async {
    try {
      final data = await _api.postJsonEnvelope(
        '/device/app/api/xiaozhi-mcp/bindings',
        {
          'mcpToken': mcpToken.trim(),
          'speakerMac': speakerMac.trim(),
          'alias': alias.trim(),
        },
      );
      if (data == null) {
        throw ApiBusinessException(-1, '添加失败，请稍后重试');
      }
      return XiaozhiMcpBindingAddResult.fromJson(data);
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }

  /// 更新备注。
  Future<void> updateAlias({required int id, required String alias}) async {
    try {
      await _api.putJsonEnvelope(
        '/device/app/api/xiaozhi-mcp/bindings/$id/alias',
        {'alias': alias.trim()},
      );
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }

  /// 删除绑定。
  Future<void> delete(int id) async {
    try {
      await _api.deleteEnvelope('/device/app/api/xiaozhi-mcp/bindings/$id');
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }
}
