export 'wechat_web_redirect_stub.dart' if (dart.library.html) 'wechat_impl_web.dart'
    show clearPendingWeChatWebOAuthStorage,
        consumeWeChatOAuthCallbackError,
        handleWeChatOAuthCallbackQuery,
        hasPendingWeChatWebCode,
        redirectToWeChatWebAuthorize;
