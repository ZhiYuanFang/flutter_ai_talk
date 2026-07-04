import 'package:flutter/material.dart';

import '../../theme/ucg_theme.dart';
import 'ucg_force_tier_icon.dart';

/// 左对齐头像 + 右上昵称/关注数/IP 属地；简介在头像行下方；可选操作按钮行。
class UcgProfileHeader extends StatelessWidget {
  const UcgProfileHeader({
    super.key,
    required this.avatar,
    required this.nickname,
    this.bio,
    this.bioPlaceholder,
    this.onBioTap,
    this.followingCount,
    this.onFollowingTap,
    this.forceValue = 0,
    this.forceTier,
    this.ipLocationText,
    this.nicknameTrailing,
    this.actions,
    this.nicknameLiftKey,
    this.bioLiftKey,
  });

  final Widget avatar;
  final String nickname;
  final String? bio;
  final String? bioPlaceholder;
  final VoidCallback? onBioTap;
  final int? followingCount;
  final VoidCallback? onFollowingTap;
  final int forceValue;
  final String? forceTier;
  final String? ipLocationText;
  final Widget? nicknameTrailing;
  final Widget? actions;
  final GlobalKey? nicknameLiftKey;
  final GlobalKey? bioLiftKey;

  @override
  Widget build(BuildContext context) {
    final fg = UcgTheme.onShell(context);
    final bioText = bio?.trim();
    final showBio = bioText != null && bioText.isNotEmpty;
    final placeholder = bioPlaceholder ?? '点击编辑个人简介';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    key: nicknameLiftKey,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          nickname.isEmpty ? '未设置昵称' : nickname,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: fg,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (nicknameTrailing != null) ...[
                        const SizedBox(width: 2),
                        nicknameTrailing!,
                      ],
                    ],
                  ),
                  if (followingCount != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UcgForceTierIcon(forceValue: forceValue, forceTier: forceTier, size: 12),
                        if (forceValue >= 500) const SizedBox(width: 4),
                        UcgFollowingCountChip(
                          count: followingCount!,
                          onTap: onFollowingTap,
                        ),
                      ],
                    ),
                  ],
                  if (ipLocationText != null && ipLocationText!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ipLocationText!,
                      style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.52), height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (onBioTap != null || showBio) ...[
          const SizedBox(height: 10),
          GestureDetector(
            key: bioLiftKey,
            onTap: onBioTap,
            behavior: HitTestBehavior.opaque,
            child: Text(
              showBio ? bioText : placeholder,
              style: TextStyle(
                fontSize: 13,
                color: showBio ? fg.withValues(alpha: 0.65) : fg.withValues(alpha: 0.42),
                height: 1.4,
                fontStyle: showBio ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
        if (actions != null) ...[
          const SizedBox(height: 14),
          actions!,
        ],
      ],
    );
  }
}

/// 关注数：小字纯文本，无 pill 背景。
class UcgFollowingCountChip extends StatelessWidget {
  const UcgFollowingCountChip({super.key, required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = UcgTheme.onShell(context);
    final text = Text(
      '关注 $count',
      style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.55), height: 1.2),
    );
    if (onTap == null) return text;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: text);
  }
}

/// 紧凑资料页操作按钮（垂直 padding 3px）。
class UcgProfileCompactButton extends StatelessWidget {
  const UcgProfileCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;

  static const _verticalPad = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = UcgTheme.scheme(context);
    final bg = filled ? scheme.primary : UcgTheme.transparentFill(context, alpha: 0.9);
    final fg = filled ? scheme.onPrimary : UcgTheme.onShell(context);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: _verticalPad),
          child: Center(
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Text(
                    label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 他人主页：关注 + 私信并排。
class UcgProfileActionRow extends StatelessWidget {
  const UcgProfileActionRow({
    super.key,
    required this.isFollowing,
    required this.onFollow,
    required this.onMessage,
    this.followBusy = false,
  });

  final bool isFollowing;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final bool followBusy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: UcgProfileCompactButton(
            label: isFollowing ? '已关注' : '关注',
            filled: !isFollowing,
            busy: followBusy,
            onPressed: onFollow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: UcgProfileCompactButton(
            label: '私信',
            filled: false,
            onPressed: onMessage,
          ),
        ),
      ],
    );
  }
}
