import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import 'xiaozhi_mcp_models.dart';

/// 小智 MCP 开通态与建单（独立于 feature catalog）。
class XiaozhiMcpUnlockRepository {
  XiaozhiMcpUnlockRepository(
    this._api, {
    void Function(String message)? onToastError,
  }) : _onToastError = onToastError ?? ((_) {});

  final ApiClient _api;
  final void Function(String message) _onToastError;

  /// 开通态 + 可售 SKU。
  Future<XiaozhiMcpUnlockView> fetchUnlock() async {
    try {
      final data = await _api.getEnvelope('/cash/app/api/xiaozhi-mcp/unlock');
      if (data == null) {
        throw ApiBusinessException(-1, '开通态查询失败');
      }
      return XiaozhiMcpUnlockView.fromJson(data);
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }

  /// 创建永久开通订单；服务端固定 MCP SKU，仅传 channel。
  Future<XiaozhiMcpOrder> createOrder({required String channel}) async {
    final ch = channel.trim();
    try {
      final data = await _api.postJsonEnvelope(
        '/cash/app/api/xiaozhi-mcp/orders',
        {'channel': ch},
      );
      if (data == null) {
        throw ApiBusinessException(-1, '建单失败，请稍后重试');
      }
      return XiaozhiMcpOrder.fromJson(data);
    } on ApiBusinessException catch (e) {
      _onToastError(e.message);
      rethrow;
    } on ApiHttpException catch (e) {
      _onToastError('网络错误(${e.statusCode})');
      rethrow;
    }
  }
}
