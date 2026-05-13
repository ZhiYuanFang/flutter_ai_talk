import 'wechat_auth_client.dart';
import 'wechat_impl_stub.dart' if (dart.library.html) 'wechat_impl_web.dart' if (dart.library.io) 'wechat_impl_mobile.dart'
    as impl;

WeChatAuthClient? createWeChatAuthClient() => impl.createWeChatAuthClient();
