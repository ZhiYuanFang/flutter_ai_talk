import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/sign_in_channel_store.dart';

/// 内存中的登录渠道；冷启动须在 [restoreFromPrefs] 后与 prefs 对齐。
class SignInChannelNotifier extends Notifier<SignInChannel> {
  @override
  SignInChannel build() => SignInChannel.unknown;

  Future<void> restoreFromPrefs() async {
    state = await SignInChannelStore.load();
  }

  Future<void> setDevice() async {
    await SignInChannelStore.save(SignInChannel.device);
    state = SignInChannel.device;
  }

  Future<void> setWechat() async {
    await SignInChannelStore.save(SignInChannel.wechat);
    state = SignInChannel.wechat;
  }

  Future<void> setApple() async {
    await SignInChannelStore.save(SignInChannel.apple);
    state = SignInChannel.apple;
  }

  Future<void> setUsername() async {
    await SignInChannelStore.save(SignInChannel.username);
    state = SignInChannel.username;
  }

  Future<void> clear() async {
    await SignInChannelStore.clear();
    state = SignInChannel.unknown;
  }
}

final signInChannelProvider = NotifierProvider<SignInChannelNotifier, SignInChannel>(
  SignInChannelNotifier.new,
);
