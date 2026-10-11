import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/app_debug_log.dart';
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

  /// 引导视频清单；失败或空一律返回 []（不 Toast，由 UI 藏入口）。
  Future<List<XiaozhiMcpGuideVideoItem>> listGuideVideos() async {
    try {
      final data =
          await _api.getEnvelope('/cash/app/api/xiaozhi-mcp/guide-videos');
      if (data == null) {
        AppDebugLog.xiaozhiGuide('guide-videos empty data');
        return const [];
      }
      final raw = data['list'];
      if (raw is! List) {
        AppDebugLog.xiaozhiGuide('guide-videos list missing');
        return const [];
      }
      final out = <XiaozhiMcpGuideVideoItem>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final item =
            XiaozhiMcpGuideVideoItem.fromJson(Map<String, dynamic>.from(e));
        // 无有效播放地址的项不展示。
        if (item.videoCdnUrl.trim().isEmpty) continue;
        out.add(item);
      }
      AppDebugLog.xiaozhiGuide('guide-videos ok count=${out.length}');
      return out;
    } on ApiBusinessException catch (e) {
      AppDebugLog.xiaozhiGuide(
        'guide-videos business err=${e.code} ${e.message}',
      );
      return const [];
    } on ApiHttpException catch (e) {
      AppDebugLog.xiaozhiGuide('guide-videos http err=${e.statusCode}');
      return const [];
    } catch (e) {
      AppDebugLog.xiaozhiGuide('guide-videos err=$e');
      return const [];
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
