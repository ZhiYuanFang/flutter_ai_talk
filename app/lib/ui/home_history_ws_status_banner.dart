import 'package:flutter/material.dart';

const _kBannerHeight = 44.0;

const kHomeHistoryWsDisconnectMessage = '连接中断，请点击重连';
const kHomeHistoryWsAutoReconnectMessage = '正在重连…';
const kHomeHistoryWsRefreshRecoveryMessage = '正在恢复连接…';
const kHomeHistoryWsGaveUpMessage = '连接失败，请检查网络后点击重连';

enum HomeHistoryWsBannerVariant { error, info }

/// 历史 WebSocket 断开时，展示于历史列表与输入区之间的内联重连横幅。
class HomeHistoryWsStatusBanner extends StatelessWidget {
  const HomeHistoryWsStatusBanner({
    super.key,
    required this.visible,
    required this.message,
    required this.onReconnect,
    this.reconnecting = false,
    this.tapEnabled = true,
    this.variant = HomeHistoryWsBannerVariant.error,
  });

  final bool visible;
  final String message;
  final VoidCallback onReconnect;
  final bool reconnecting;
  final bool tapEnabled;
  final HomeHistoryWsBannerVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final infoStyle = variant == HomeHistoryWsBannerVariant.info;
    final containerColor = infoStyle ? scheme.primaryContainer : scheme.errorContainer;
    final onContainer = infoStyle ? scheme.onPrimaryContainer : scheme.onErrorContainer;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? Material(
              color: containerColor,
              child: InkWell(
                onTap: tapEnabled ? onReconnect : null,
                child: SizedBox(
                  height: _kBannerHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (reconnecting)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onContainer,
                            ),
                          )
                        else
                          Icon(
                            infoStyle ? Icons.sync_outlined : Icons.cloud_off_outlined,
                            size: 20,
                            color: onContainer,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: onContainer,
                            ),
                          ),
                        ),
                        if (tapEnabled)
                          Icon(Icons.refresh, size: 20, color: onContainer),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
