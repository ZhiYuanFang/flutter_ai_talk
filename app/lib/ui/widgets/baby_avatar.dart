import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/baby_avatar_local_store.dart';
import '../../data/models.dart';
import '../../providers/baby_avatar_provider.dart';
import '../baby_profile_clay_theme.dart';

/// 宝宝头像：有本地文件则展示；否则按性别色默认剪影（男蓝/女粉/未知灰）。
class BabyAvatar extends ConsumerStatefulWidget {
  const BabyAvatar({
    super.key,
    required this.babyId,
    required this.sex,
    this.radius = 22,
    this.onTap,
  });

  final String babyId;
  final BabySex sex;
  final double radius;
  final VoidCallback? onTap;

  @override
  ConsumerState<BabyAvatar> createState() => _BabyAvatarState();
}

class _BabyAvatarState extends ConsumerState<BabyAvatar> {
  File? _file;
  var _loading = true;
  var _lastRevision = -1;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant BabyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.babyId != widget.babyId || oldWidget.sex != widget.sex) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (kIsWeb || widget.babyId.isEmpty) {
      if (mounted) {
        setState(() {
          _file = null;
          _loading = false;
        });
      }
      return;
    }
    setState(() => _loading = true);
    final file = await BabyAvatarLocalStore.resolveFile(widget.babyId);
    if (!mounted) return;
    setState(() {
      _file = file;
      _loading = false;
    });
  }

  Color get _placeholderColor => switch (widget.sex) {
        BabySex.male => BabyProfileClayTheme.accentBlue,
        BabySex.female => BabyProfileClayTheme.accentPink,
        BabySex.unknown => const Color(0xFF9E9E9E),
      };

  @override
  Widget build(BuildContext context) {
    // 选图落盘后 revision 自增，触发重载
    final revision = ref.watch(babyAvatarRevisionProvider);
    if (revision != _lastRevision) {
      _lastRevision = revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload();
      });
    }

    final diameter = widget.radius * 2;
    final child = _loading
        ? SizedBox(
            width: diameter,
            height: diameter,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : CircleAvatar(
            radius: widget.radius,
            backgroundColor: _file == null
                ? _placeholderColor.withValues(alpha: 0.25)
                : Colors.transparent,
            backgroundImage: _file != null ? FileImage(_file!) : null,
            child: _file == null
                ? Icon(
                    Icons.child_care_rounded,
                    size: widget.radius * 1.15,
                    color: _placeholderColor,
                  )
                : null,
          );

    if (widget.onTap == null) return child;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: child,
      ),
    );
  }
}
