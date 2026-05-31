import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/gateway_json.dart';
import '../session/sign_in_channel_store.dart';
import 'models.dart';
import 'repositories.dart' show SettingsRepository;

typedef _DeviceNoGetter = String? Function();

/// 画像读取 `GET /device/app/api/user/get`；保存：仅胖宝号登录渠道走 `POST /device/app/api/user/save`，
/// 其余渠道（`wechat`、`username`、`unknown`）走 `auto_save`。
/// 昵称在 `user/save` 请求体中上传；`user/get` 与本地 prefs 仍用于展示合并。
class RemoteSettingsRepository implements SettingsRepository {
  RemoteSettingsRepository(
    this._api,
    this._deviceNoGetter, {
    required SignInChannel Function() signInChannelGetter,
    void Function(String message)? onToast,
  })  : _signInChannelGetter = signInChannelGetter,
        _onToast = onToast ?? ((m) {});

  final ApiClient _api;
  final _DeviceNoGetter _deviceNoGetter;
  final SignInChannel Function() _signInChannelGetter;
  final void Function(String message) _onToast;

  static String _prefsKey(String deviceNo) => 'pangbao_baby_profile_$deviceNo';

  /// 占位生日：当年 6 月 1 日；若尚未到（如 5 月）则用当年 1 月 1 日，避免晚于「今天」。
  DateTime _placeholderBirthSameYear() {
    final now = DateTime.now();
    final j6 = DateTime(now.year, 6, 1);
    if (!j6.isAfter(now)) return j6;
    return DateTime(now.year, 1, 1);
  }

  DateTime _clampCalendarBirth(DateTime raw) {
    final d = DateTime(raw.year, raw.month, raw.day);
    final now = DateTime.now();
    final last = DateTime(now.year, now.month, now.day);
    if (d.isAfter(last)) return last;
    final first = DateTime(2000);
    if (d.isBefore(first)) return first;
    return d;
  }

  BabyProfile _defaultsForDevice(String deviceNo) => BabyProfile(
        id: deviceNo,
        nickname: '',
        sex: BabySex.unknown,
        birthDate: _placeholderBirthSameYear(),
      );

  BabyProfile _profileFromUserGet(
    Map<String, dynamic> data,
    String requestDeviceNo, {
    String? nicknameFromLocal,
  }) {
    final id = readGatewayStr(data, 'deviceNo', 'device_no') ?? requestDeviceNo;
    final sexInt = _readInt(data['sex']) ?? -1;
    final sex = switch (sexInt) {
      1 => BabySex.male,
      0 => BabySex.female,
      _ => BabySex.unknown,
    };
    final sec = _readInt(data['birthday']);
    DateTime birthDate;
    if (sec != null && sec > 0) {
      final instant = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
      birthDate = _clampCalendarBirth(DateTime(instant.year, instant.month, instant.day));
    } else {
      birthDate = _placeholderBirthSameYear();
    }
    final nick = readGatewayStr(data, 'babyName', 'nickname') ?? nicknameFromLocal;
    final nickname =
        (nick != null && nick.trim().isNotEmpty) ? nick.trim() : '';
    return BabyProfile(id: id, nickname: nickname, sex: sex, birthDate: birthDate);
  }

  int? _readInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  Future<BabyProfile> loadBaby() async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      return BabyProfile(
        id: '',
        nickname: '未绑定宝宝ID',
        sex: BabySex.unknown,
        birthDate: DateTime(DateTime.now().year, 1, 1),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    BabyProfile? localParsed;
    final raw = prefs.getString(_prefsKey(dn));
    if (raw != null && raw.isNotEmpty) {
      try {
        localParsed = BabyProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }

    try {
      final data = await _api.getEnvelope(
        '/device/app/api/user/get',
        query: {'deviceNo': dn},
      );
      if (data != null && data.isNotEmpty) {
        final merged = _profileFromUserGet(
          data,
          dn,
          nicknameFromLocal: localParsed?.nickname,
        );
        await prefs.setString(_prefsKey(merged.id), jsonEncode(merged.toJson()));
        return merged;
      }
    } on ApiBusinessException {
      // 静默回退：避免启动/设置页每次打开都弹业务错误
    } catch (_) {}

    if (localParsed != null) return localParsed;
    return _defaultsForDevice(dn);
  }

  int _sexToApi(BabySex s) => switch (s) {
        BabySex.female => 0,
        BabySex.male => 1,
        BabySex.unknown => 0,
      };

  @override
  Future<void> saveBaby(BabyProfile profile) async {
    final dn = _deviceNoGetter();
    if (dn == null || dn.isEmpty) {
      throw StateError('未绑定宝宝ID，无法保存画像');
    }
    final midnight = DateTime(profile.birthDate.year, profile.birthDate.month, profile.birthDate.day);
    try {
      final Map<String, dynamic>? data = _signInChannelGetter() == SignInChannel.device
          ? await _api.postJsonEnvelope(
              '/device/app/api/user/save',
              {
                'deviceNo': dn,
                'birthday': midnight.millisecondsSinceEpoch ~/ 1000,
                'sex': _sexToApi(profile.sex),
                'babyName': profile.nickname.trim(),
              },
            )
          : await _api.postJsonEnvelope(
              '/device/app/api/user/auto_save',
              {
                'birthday': midnight.millisecondsSinceEpoch ~/ 1000,
                'sex': _sexToApi(profile.sex),
                'babyName': profile.nickname.trim(),
              },
            );
      final returned = readGatewayStr(data ?? const {}, 'deviceNo', 'device_no') ?? dn;
      final prefs = await SharedPreferences.getInstance();
      final toStore = profile.copyWith(id: returned);
      await prefs.setString(_prefsKey(returned), jsonEncode(toStore.toJson()));
    } on ApiBusinessException catch (e) {
      _onToast(e.message);
      rethrow;
    }
  }
}