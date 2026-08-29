import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_widget/has_pinned_home_widget.dart';
import '../home_widget/home_widget_sync.dart';
import '../theme/app_color.dart';
import 'widgets/app_toast.dart';
import 'widgets/home_widget_large_preview.dart';

/// 桌面小组件展示 / 添加引导页。
class HomeWidgetShowcaseScreen extends ConsumerStatefulWidget {
  const HomeWidgetShowcaseScreen({super.key});

  @override
  ConsumerState<HomeWidgetShowcaseScreen> createState() =>
      _HomeWidgetShowcaseScreenState();
}

class _HomeWidgetShowcaseScreenState
    extends ConsumerState<HomeWidgetShowcaseScreen>
    with WidgetsBindingObserver {
  var _pinned = false;
  var _ready = false;
  var _refreshing = false;
  var _previewEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshPinned());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPinned());
    }
  }

  Future<void> _refreshPinned() async {
    final pinned = await hasPinnedHomeWidget();
    if (!mounted) return;
    setState(() {
      _pinned = pinned;
      _ready = true;
    });
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await ensureWidgetReadyFromRef(ref);
      if (!mounted) return;
      setState(() => _previewEpoch++);
      showAppToast('小组件数据已更新', tone: AppToastTone.success);
    } catch (_) {
      if (!mounted) return;
      showAppToast('刷新失败，请稍后重试', tone: AppToastTone.error);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onShell = AppColor.textPrimary(context);
    final muted = AppColor.textMuted(context);
    final title = !_ready
        ? '桌面小组件'
        : (_pinned ? '查看桌面小组件' : '添加桌面小组件');

    return Scaffold(
      backgroundColor: AppColor.pageBg(context),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (_ready && !_pinned) ...[
            Text(
              '如何添加',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onShell,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _setupCopy(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: muted,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 20),
          ],
          if (_ready && _pinned) ...[
            Text(
              '桌面能力',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onShell,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '在系统桌面直接查看宝宝的即将发生事件、最近记录与「值得留意」提示。'
              '支持小 / 中 / 大三种尺寸；大尺寸可展示更多行与提示。'
              '数据由胖宝 App 推送，无需打开应用也能扫一眼节奏。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: muted,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            '大尺寸预览',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onShell,
                ),
          ),
          const SizedBox(height: 10),
          HomeWidgetLargePreview(key: ValueKey(_previewEpoch)),
          if (_ready && _pinned) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _refreshing ? null : () => unawaited(_onRefresh()),
              child: Text(_refreshing ? '刷新中…' : '刷新小组件数据'),
            ),
          ],
        ],
      ),
    );
  }

  String _setupCopy() {
    if (kIsWeb) {
      return '请在手机上的胖宝 App 中添加桌面小组件。';
    }
    if (Platform.isIOS) {
      return '1. 回到 iPhone 主屏幕，长按空白处进入编辑模式。\n'
          '2. 点左上角「+」，搜索「胖宝」。\n'
          '3. 选择小 / 中 / 大尺寸后点「添加小组件」。\n'
          '4. 添加后回到本页，可查看能力说明并刷新数据。';
    }
    return '1. 回到手机桌面，长按空白处或两指捏合进入编辑。\n'
        '2. 选择「小组件 / 窗口小工具」，找到「胖宝」。\n'
        '3. 拖入小 / 中 / 大尺寸到桌面。\n'
        '4. 若系统提供「添加到桌面」入口，也可从应用信息页添加。\n'
        '5. 添加后回到本页，可查看能力说明并刷新数据。';
  }
}
