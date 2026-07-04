import 'package:flutter/material.dart';

import '../../data/ucg_models.dart';
import '../../theme/ucg_theme.dart';
import 'ucg_debate_vs_bar.dart';
import 'ucg_feed_moments_widgets.dart';

const _kTimelineDateColumnWidth = 64.0;

const _kChineseMonths = [
  '一月',
  '二月',
  '三月',
  '四月',
  '五月',
  '六月',
  '七月',
  '八月',
  '九月',
  '十月',
  '十一月',
  '十二月',
];

/// WeChat「我的朋友圈」风格：左日期列 + 右正文/媒体。
class UcgMyPostTimelineItem extends StatelessWidget {
  const UcgMyPostTimelineItem({
    super.key,
    required this.post,
    this.showDateColumn = true,
    this.showDivider = true,
    this.onTap,
  });

  final UcgPost post;
  final bool showDateColumn;
  final bool showDivider;
  final VoidCallback? onTap;

  static String chineseMonthName(int month) => _kChineseMonths[month - 1];

  static String formatDay(DateTime date) => date.day.toString().padLeft(2, '0');

  static String formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final date = post.displayAt.toLocal();
    final monthLabel = chineseMonthName(date.month);
    final dayLabel = formatDay(date);
    final fg = UcgTheme.onShell(context);
    final muted = fg.withValues(alpha: 0.45);
    final dividerColor = fg.withValues(alpha: 0.18);
    final timeLabel = formatTime(date);
    final hasMedia = post.imageUrls.isNotEmpty || post.videoUrl != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _kTimelineDateColumnWidth,
            child: showDateColumn
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthLabel,
                        style: TextStyle(fontSize: 12, color: muted, height: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          height: 1.05,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (UcgPostAuditBadge.visibleFor(post))
                  Align(
                    alignment: Alignment.centerRight,
                    child: UcgPostAuditBadge(post: post),
                  ),
                if (post.status == UcgPostStatus.rejected &&
                    post.rejectReason != null &&
                    post.rejectReason!.isNotEmpty) ...[
                  if (UcgPostAuditBadge.visibleFor(post)) const SizedBox(height: 6),
                  Text(
                    post.rejectReason!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (post.text.isNotEmpty) ...[
                  if (UcgPostAuditBadge.visibleFor(post) ||
                      (post.status == UcgPostStatus.rejected &&
                          post.rejectReason != null &&
                          post.rejectReason!.isNotEmpty))
                    const SizedBox(height: 8),
                  Text(
                    post.text,
                    maxLines: post.isDebate ? null : 2,
                    overflow: post.isDebate ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.9),
                      height: 1.45,
                      fontSize: 15,
                      fontWeight: post.isDebate ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
                if (hasMedia)
                  UcgPostMediaSection(
                    post: post,
                    topSpacing: 8,
                    maxPreviewImages: post.isDebate ? 3 : null,
                    openLightboxOnTap: false,
                  ),
                if (post.isDebate) ...[
                  if (hasMedia || post.text.isNotEmpty) const SizedBox(height: 10),
                  UcgDebateVsBar(
                    leftLabel: post.debateLeft,
                    rightLabel: post.debateRight,
                    leftRatio: post.debateLeftRatio,
                    rightRatio: post.debateRightRatio,
                    totalVotes: post.leftVoteCount + post.rightVoteCount,
                    myVoteSide: post.myVoteSide,
                    interactive: false,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  timeLabel,
                  style: TextStyle(fontSize: 12, color: muted, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onTap == null)
          content
        else
          InkWell(onTap: onTap, child: content),
        if (showDivider)
          Row(
            children: [
              const SizedBox(width: _kTimelineDateColumnWidth),
              Expanded(
                child: Divider(height: 1, thickness: 1, color: dividerColor),
              ),
            ],
          ),
      ],
    );
  }
}
