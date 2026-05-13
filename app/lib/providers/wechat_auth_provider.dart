import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../wechat/wechat_auth_client.dart';
import '../wechat/wechat_factory.dart';

final weChatAuthClientProvider = Provider<WeChatAuthClient?>((ref) {
  return createWeChatAuthClient();
});
