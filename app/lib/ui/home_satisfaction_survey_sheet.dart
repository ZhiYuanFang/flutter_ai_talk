import 'package:flutter/material.dart';

import '../api/api_exceptions.dart';
import '../data/satisfaction_survey_repository.dart';
import '../theme/app_color.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';

const _kSurveyCommentMaxScalars = 1000;

/// 一行选项上的互斥评价。未选不使用这个枚举。
enum _SurveyRating {
  bad('不好用'),
  good('好用');

  const _SurveyRating(this.label);

  final String label;
}

/// 满意度问卷 sheet。成功才关闭；失败在提交按钮上方展示，不 toast。
Future<void> showHomeSatisfactionSurveySheet(
  BuildContext context, {
  required SatisfactionSurveyCurrent current,
  required SatisfactionSurveyRepository repo,
}) {
  return showGlassAdaptiveBottomSheet<void>(
    context: context,
    respectKeyboardInset: true,
    maxHeightFraction: 0.86,
    // 外层不再整页滚，标题和底部提交留在列表外。
    scrollable: false,
    bodyBuilder: (ctx) => _SurveySheetBody(current: current, repo: repo),
  );
}

class _SurveySheetBody extends StatefulWidget {
  const _SurveySheetBody({required this.current, required this.repo});

  final SatisfactionSurveyCurrent current;
  final SatisfactionSurveyRepository repo;

  @override
  State<_SurveySheetBody> createState() => _SurveySheetBodyState();
}

class _SurveySheetBodyState extends State<_SurveySheetBody> {
  final _comment = TextEditingController();
  /// 选项 id → 评价。没有键表示这一行还没选。
  final _ratings = <int, _SurveyRating>{};
  var _submitting = false;
  var _error = '';

  @override
  void initState() {
    super.initState();
    // 改意见后清掉按钮上方的旧错误。
    _comment.addListener(_clearError);
  }

  @override
  void dispose() {
    _comment.removeListener(_clearError);
    _comment.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error.isEmpty || !mounted) return;
    setState(() => _error = '');
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final comment = _comment.text.trim();
    // 与服务端一致：按 Unicode 码位计数，避免表情字素把超长请求放出去。
    if (comment.runes.length > _kSurveyCommentMaxScalars) {
      _showError('意见不能超过 1000 字');
      return;
    }
    final results = <String>[];
    for (final option in widget.current.options) {
      final rating = _ratings[option.id];
      // 没点的行不提交，也不补成任何评价。
      if (rating == null) continue;
      results.add('${option.text}${rating.label}');
    }
    if (results.isEmpty && comment.isEmpty) {
      _showError('请至少选择一项或填写意见');
      return;
    }
    if (widget.current.campaignId < 1) {
      _showError('问卷当前不可提交');
      return;
    }
    setState(() {
      _submitting = true;
      _error = '';
    });
    try {
      await widget.repo.submit(
        campaignId: widget.current.campaignId,
        optionResults: results,
        comment: comment,
      );
      if (!mounted) return;
      showAppToast('感谢您的宝贵意见', tone: AppToastTone.success);
      Navigator.of(context).pop();
    } on ApiBusinessException catch (e) {
      final message = e.message.trim();
      _showError(message.isEmpty ? '提交失败，请稍后再试' : message);
    } catch (_) {
      _showError('提交失败，请稍后再试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final intro = widget.current.intro;
    final options = widget.current.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '满意度·意见收集',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              if (intro.isNotEmpty) ...[
                Text(
                  intro,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColor.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          option.text.isEmpty ? '选项' : option.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.textPrimary(context),
                          ),
                        ),
                      ),
                      for (final rating in _SurveyRating.values)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _SurveyRatingChip(
                            label: rating.label,
                            colors: _colorsFor(
                              context,
                              rating,
                              _ratings[option.id] == rating,
                            ),
                            enabled: !_submitting,
                            onTap: () {
                              setState(() {
                                _error = '';
                                _ratings[option.id] = rating;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          enabled: !_submitting,
          maxLength: _kSurveyCommentMaxScalars,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(color: AppColor.textPrimary(context)),
          decoration: InputDecoration(
            labelText: '更多意见',
            labelStyle: TextStyle(color: AppColor.textMuted(context)),
            counterStyle: TextStyle(color: AppColor.textMuted(context)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.fieldBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.primary(context)),
            ),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _error,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColor.error(context),
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _submitting ? null : () => _submit(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.primary(context),
            foregroundColor: AppColor.onPrimary(context),
          ),
          child: Text(_submitting ? '提交中…' : '提交'),
        ),
      ],
    );
  }
}

/// 一种评价的底、边和字。未选浅底，选中实底，同一色系。
class _SurveyChipColors {
  const _SurveyChipColors({
    required this.fill,
    required this.border,
    required this.foreground,
  });

  final Color fill;
  final Color border;
  final Color foreground;
}

/// 不好用走错误色，好用走主题色。
_SurveyChipColors _colorsFor(
  BuildContext context,
  _SurveyRating rating,
  bool selected,
) {
  switch (rating) {
    case _SurveyRating.bad:
      final error = AppColor.error(context);
      if (selected) {
        return _SurveyChipColors(
          fill: error,
          border: error,
          foreground: AppColor.onError(context),
        );
      }
      return _SurveyChipColors(
        fill: error.withValues(alpha: 0.16),
        border: error,
        foreground: error,
      );
    case _SurveyRating.good:
      final primary = AppColor.primary(context);
      if (selected) {
        return _SurveyChipColors(
          fill: primary,
          border: primary,
          foreground: AppColor.onPrimary(context),
        );
      }
      return _SurveyChipColors(
        fill: primary.withValues(alpha: 0.16),
        border: primary,
        foreground: primary,
      );
  }
}

/// 右侧单个评价。底和边由 [_colorsFor] 按评价种类给出。
class _SurveyRatingChip extends StatelessWidget {
  const _SurveyRatingChip({
    required this.label,
    required this.colors,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final _SurveyChipColors colors;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.fill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.foreground),
          ),
        ),
      ),
    );
  }
}
