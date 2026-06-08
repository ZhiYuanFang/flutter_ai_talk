import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/feedback_models.dart';
import '../providers/feedback_provider.dart';
import '../providers/toast_bus.dart';
import '../theme/app_visual_tokens.dart';
import 'widgets/settings_glass_panel.dart';

class FeedbackListScreen extends ConsumerStatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  ConsumerState<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends ConsumerState<FeedbackListScreen> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ref.showApiToast('请输入反馈内容');
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(feedbackRepositoryProvider);
      await repo.submit(text);
      _inputController.clear();
      _inputFocus.unfocus();
      ref.invalidate(feedbackListProvider);
      if (mounted) ref.showApiToast('提交成功，感谢你的反馈');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatTime(int unixSec) {
    if (unixSec <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(feedbackListProvider);
    final scheme = Theme.of(context).colorScheme;
    final tokens = visualTokensOf(context);
    final onShell = tokens?.onShell ?? scheme.onSurface;
    final bgStart = tokens?.shellColor ?? scheme.surface;
    final bgEnd = Color.lerp(bgStart, scheme.primaryContainer, 0.4) ?? scheme.surface;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('反馈建议'),
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
          child: Column(
            children: [
              Expanded(
                child: listAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('加载失败：$e', style: TextStyle(color: onShell)),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          SettingsGlassPanel(
                            child: Text(
                              '欢迎提出建议，我们会认真阅读每一条反馈。',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: onShell.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _FeedbackCard(
                        item: items[index],
                        onShell: onShell,
                        formatTime: _formatTime,
                      ),
                    );
                  },
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                child: SettingsGlassPanel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          focusNode: _inputFocus,
                          maxLines: 4,
                          minLines: 1,
                          maxLength: 2000,
                          decoration: InputDecoration(
                            hintText: '写下你的建议或问题…',
                            border: InputBorder.none,
                            counterText: '',
                            hintStyle: TextStyle(color: onShell.withValues(alpha: 0.45)),
                          ),
                          style: TextStyle(color: onShell),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: _submitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : const Text('提交'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.item,
    required this.onShell,
    required this.formatTime,
  });

  final FeedbackItem item;
  final Color onShell;
  final String Function(int unixSec) formatTime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondary = onShell.withValues(alpha: 0.65);
    final muted = onShell.withValues(alpha: 0.45);

    return SettingsGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.question,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: onShell,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatTime(item.createdAt),
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: onShell.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          if (item.isReplied) ...[
            Text(
              '官方回复',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.officialReply ?? '',
              style: TextStyle(fontSize: 14, height: 1.45, color: secondary),
            ),
            if (item.repliedAt != null && item.repliedAt! > 0) ...[
              const SizedBox(height: 6),
              Text(
                formatTime(item.repliedAt!),
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ] else
            Text(
              '等待官方回复',
              style: TextStyle(fontSize: 14, color: muted, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}
