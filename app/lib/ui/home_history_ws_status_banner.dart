import 'package:flutter/material.dart';

const _kBannerHeight = 44.0;

const kHomeHistoryWsDisconnectMessage = '连接中断，请点击重连';

/// 历史 WebSocket 断开时，展示于历史列表与输入区之间的内联重连横幅。
class HomeHistoryWsStatusBanner extends StatelessWidget {
  const HomeHistoryWsStatusBanner({
    super.key,
    required this.visible,
    required this.onReconnect,
    this.reconnecting = false,
  });

  final bool visible;
  final VoidCallback onReconnect;
  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onErrorContainer;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? Material(
              color: scheme.errorContainer,
              child: InkWell(
                onTap: reconnecting ? null : onReconnect,
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
                          Icon(Icons.cloud_off_outlined, size: 20, color: onContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            kHomeHistoryWsDisconnectMessage,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: onContainer,
                            ),
                          ),
                        ),
                        if (!reconnecting)
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
