import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../config/baby_avatar_local_store.dart';
import '../data/models.dart';
import '../../home_widget/home_widget_sync.dart';
import '../providers/baby_avatar_provider.dart';
import '../providers/repositories.dart';
import '../providers/settings_baby.dart';
import '../theme/app_theme_scope.dart';
import '../theme/theme_bootstrap_cache.dart';
import 'baby_profile_clay_theme.dart';
import 'clay_form_widgets.dart';
import 'widgets/app_glass_overlay.dart';
import 'widgets/app_toast.dart';
import 'widgets/baby_avatar.dart';

/// 宝宝资料表单：加载 [initialBaby]，保存后刷新 [settingsBabyProvider] 与主题性别。
/// [onSaved] 在保存成功且 SnackBar 展示前调用（例如返回上一级）。
class BabyProfileEditor extends ConsumerStatefulWidget {
  const BabyProfileEditor({super.key, required this.initialBaby, this.onSaved});

  final BabyProfile initialBaby;
  final VoidCallback? onSaved;

  @override
  ConsumerState<BabyProfileEditor> createState() => _BabyProfileEditorState();
}

class _BabyProfileEditorState extends ConsumerState<BabyProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late BabySex _sex;
  late DateTime _birth;

  static final _birthFmt = DateFormat('yyyy-MM-dd');
  static final DateTime _firstBirth = DateTime(2000);

  /// 生日不可早于 2000、不可晚于今天。
  static DateTime _clampBirthToValidRange(DateTime birth) {
    final last = DateTime.now();
    final d = DateTime(birth.year, birth.month, birth.day);
    if (d.isBefore(_firstBirth)) return _firstBirth;
    if (d.isAfter(last)) return DateTime(last.year, last.month, last.day);
    return d;
  }

  DateTime get _lastBirth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.initialBaby.nickname);
    _sex = widget.initialBaby.sex;
    _birth = _clampBirthToValidRange(widget.initialBaby.birthDate);
  }

  @override
  void didUpdateWidget(covariant BabyProfileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = oldWidget.initialBaby;
    final n = widget.initialBaby;
    if (o.id != n.id || o.nickname != n.nickname || o.sex != n.sex || o.birthDate != n.birthDate) {
      _nicknameCtrl.text = n.nickname;
      _sex = n.sex;
      _birth = _clampBirthToValidRange(n.birthDate);
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _onBirthChanged(DateTime raw) {
    setState(() => _birth = _clampBirthToValidRange(raw));
  }

  /// 选本地图并复制到 baby_avatar/（与历史媒体目录隔离）。
  Future<void> _pickAvatar() async {
    if (kIsWeb) {
      showAppToast('当前平台暂不支持设置宝宝头像');
      return;
    }
    final babyId = widget.initialBaby.id;
    if (babyId.isEmpty) {
      showAppToast('请先绑定宝宝后再设置头像', tone: AppToastTone.error);
      return;
    }

    final source = await showGlassAdaptiveBottomSheet<ImageSource>(
      context: context,
      scrollable: true,
      useLightGlass: true,
      glassContentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('从相册选择'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('拍照'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    try {
      await BabyAvatarLocalStore.persistAvatar(
        babyId: babyId,
        source: File(picked.path),
      );
      bumpBabyAvatarRevision(ref);
      if (!mounted) return;
      showAppToast('头像已更新', tone: AppToastTone.success);
    } catch (e) {
      if (!mounted) return;
      showAppToast('头像保存失败：$e', tone: AppToastTone.error);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = BabyProfile(
      id: widget.initialBaby.id,
      nickname: _nicknameCtrl.text.trim(),
      sex: _sex,
      birthDate: _birth,
    );
    try {
      await ref.read(settingsRepositoryProvider).saveBaby(profile);
      ref.invalidate(settingsBabyProvider);
      ref.read(babySexProvider.notifier).state = profile.sex;
      await persistCachedBabySex(profile.sex);
      await syncHomeWidgetFromRef(ref);
      if (!mounted) return;
      showAppToast('宝宝信息已保存', tone: AppToastTone.success);
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      showAppToast('保存失败：$e', tone: AppToastTone.error);
    }
  }

  void _cancel() {
    // _nicknameCtrl.text = widget.initialBaby.nickname;
    // _sex = widget.initialBaby.sex;
    // _birth = _clampBirthToValidRange(widget.initialBaby.birthDate);
    // setState(() {});
    // showAppToast('已恢复为上次加载的数据');
    // 返回上一级
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pickerH = MediaQuery.sizeOf(context).height < 640 ? 140.0 : 168.0;

    return ClayProfileCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text(
            //   '宝宝信息',
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.w700,
            //     color: BabyProfileClayTheme.textPrimaryOf(context),
            //   ),
            // ),
            // const SizedBox(height: 16),
            // 昵称上方横向居中头像；点击选本地图
            Center(
              child: BabyAvatar(
                babyId: widget.initialBaby.id,
                sex: _sex,
                radius: 40,
                onTap: () => unawaited(_pickAvatar()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '宝宝头像仅本地保存，不会同步到其他设备。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: BabyProfileClayTheme.textSecondaryOf(context).withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            const ClaySectionLabel(
              text: '宝宝昵称',
              leadingIcon: Icons.cloud_outlined,
            ),
            const SizedBox(height: 10),
            ClayInsetField(
              leading: Icon(
                Icons.child_care_rounded,
                size: 28,
                color: BabyProfileClayTheme.accentPink.withValues(alpha: 0.85),
              ),
              child: TextFormField(
                controller: _nicknameCtrl,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: BabyProfileClayTheme.textPrimaryOf(context),
                ),
                decoration: InputDecoration(
                  hintText: '待设置',
                  hintStyle: TextStyle(
                    color: BabyProfileClayTheme.textSecondaryOf(context),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                validator: (v) {
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            const ClaySectionLabel(
              text: '性别',
              leadingIcon: Icons.star_outline_rounded,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClayChoiceChip(
                    label: '男',
                    selected: _sex == BabySex.male,
                    fillColor: BabyProfileClayTheme.maleChipFill,
                    borderColor: BabyProfileClayTheme.maleChipBorder,
                    leadingDotColor: BabyProfileClayTheme.accentBlue,
                    onTap: () => setState(() => _sex = BabySex.male),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClayChoiceChip(
                    label: '女',
                    selected: _sex == BabySex.female,
                    fillColor: BabyProfileClayTheme.femaleChipFill,
                    borderColor: BabyProfileClayTheme.femaleChipBorder,
                    leadingDotColor: BabyProfileClayTheme.accentPink,
                    onTap: () => setState(() => _sex = BabySex.female),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 8),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: () => setState(() => _sex = BabySex.unknown),
            //     style: TextButton.styleFrom(
            //       foregroundColor: BabyProfileClayTheme.textSecondaryOf(context),
            //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //       minimumSize: Size.zero,
            //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //     ),
            //     child: Text(
            //       _sex == BabySex.unknown ? '✓ 暂不选择' : '暂不选择',
            //       style: TextStyle(
            //         fontSize: 13,
            //         fontWeight: _sex == BabySex.unknown ? FontWeight.w600 : FontWeight.w400,
            //         color: _sex == BabySex.unknown
            //             ? BabyProfileClayTheme.textPrimaryOf(context)
            //             : BabyProfileClayTheme.textSecondaryOf(context),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),
            const ClaySectionLabel(
              text: '生日',
              leadingIcon: Icons.cloud_outlined,
            ),
            const SizedBox(height: 10),
            Text(
              _birthFmt.format(_birth),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BabyProfileClayTheme.textPrimaryOf(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            ClayBirthDateWheel(
              value: _birth,
              minimumDate: _firstBirth,
              maximumDate: _lastBirth,
              onChanged: _onBirthChanged,
              height: pickerH,
            ),
            const SizedBox(height: 12),
            Text(
              'ID：${widget.initialBaby.id}',
              style: TextStyle(
                fontSize: 12,
                color: BabyProfileClayTheme.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BabyProfileClayTheme.textPrimaryOf(context),
                      side: BorderSide(color: BabyProfileClayTheme.insetBorderOf(context)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BabyProfileClayTheme.chipRadius),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      // accentBlue 为黏土品牌强调色例外；字色用高对比白
                      backgroundColor: BabyProfileClayTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BabyProfileClayTheme.chipRadius),
                      ),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
