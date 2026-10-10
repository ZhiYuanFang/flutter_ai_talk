import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'xiaozhi_console_link.dart';
import 'widgets/settings_glass_panel.dart';

/// 字段帮助类型：MAC 或 MCP 接入点。
enum XiaozhiSpeakerFieldHelpKind { mac, token }

/// 小智控制台字段来源说明 + 步骤图。
class XiaozhiSpeakerFieldHelpScreen extends StatelessWidget {
  const XiaozhiSpeakerFieldHelpScreen({super.key, required this.kind});

  final XiaozhiSpeakerFieldHelpKind kind;

  @override
  Widget build(BuildContext context) {
    final tokens = visualTokensOf(context);
    final scheme = Theme.of(context).colorScheme;
    final onShell = tokens?.onShell ?? AppColor.textPrimary(context);
    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd =
        Color.lerp(bgStart, scheme.primaryContainer, 0.35) ?? scheme.surface;

    final isMac = kind == XiaozhiSpeakerFieldHelpKind.mac;
    final title = isMac ? '如何获取音箱 MAC' : '如何获取 MCP 接入点';
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.45,
      color: onShell.withValues(alpha: 0.9),
    );
    final images = isMac
        ? const ['assets/images/mac_1.png', 'assets/images/mac_2.png']
        : const ['assets/images/token_1.png', 'assets/images/token_2.png'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SettingsGlassPanel(
                child: isMac
                    ? XiaozhiConsoleLinkedText(
                        leading: '打开',
                        trailing:
                            ' → 智能体卡片点「设备」→ 在设备列表「MAC 地址」列复制完整 MAC（如 3c:dc:75:fc:7f:c4）。',
                        style: bodyStyle,
                      )
                    : XiaozhiConsoleLinkedText(
                        leading: '打开',
                        trailing:
                            ' → 智能体卡片点「配置」→「扩展能力」→「MCP接入点」→ 点复制图标，粘贴完整接入点地址即可（也可只贴 token）。',
                        style: bodyStyle,
                      ),
              ),
              const SizedBox(height: 16),
              for (final path in images) ...[
                SettingsGlassPanel(
                  contentPadding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      path,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '图片加载失败',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onShell.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
