import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/env.dart';
import '../../session/token_expiry.dart';
import 'ucg_api_client.dart';
import 'ucg_models.dart';

import 'ucg_presign.dart';

typedef UcgUserIdGetter = String? Function();

/// UCG HTTP + 聊天 WebSocket（经 gateway `/ucg/app/ws/chat`）。
class UcgRepository {
  UcgRepository({
    required UcgApiClient api,
    required UcgUserIdGetter userIdGetter,
    required String? Function() accessTokenGetter,
  })  : _api = api,
        _userIdGetter = userIdGetter,
        _accessTokenGetter = accessTokenGetter;

  final UcgApiClient _api;
  final UcgUserIdGetter _userIdGetter;
  final String? Function() _accessTokenGetter;

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _reconnectTimer;
  var _wsConnected = false;
  var _shouldStayConnected = false;
  final _messageController = StreamController<UcgChatMessage>.broadcast();
  final _wsReadyController = StreamController<bool>.broadcast();
  final _notificationController = StreamController<void>.broadcast();

  Stream<UcgChatMessage> get incomingMessages => _messageController.stream;
  Stream<bool> get wsReadyStream => _wsReadyController.stream;
  Stream<void> get notificationEvents => _notificationController.stream;
  bool get isWsConnected => _wsConnected;

  void dispose() {
    _shouldStayConnected = false;
    _reconnectTimer?.cancel();
    _wsSub?.cancel();
    _ws?.sink.close();
    _messageController.close();
    _wsReadyController.close();
    _notificationController.close();
  }

  void setWsConnectionDesired(bool desired) {
    _shouldStayConnected = desired;
    if (desired) {
      unawaited(connectChatWs());
    } else {
      _tearDownWs();
    }
  }

  Future<void> connectChatWs() async {
    final url = AppEnv.wsUcgChatUrlEffective;
    final token = _accessTokenGetter();
    if (url.isEmpty || token == null || token.isEmpty) return;
    if (!isUcgWxAccountBound(readJwtWxId(token))) return;
    if (_wsConnected) return;

    _wsSub?.cancel();
    _ws?.sink.close();

    try {
      _ws = WebSocketChannel.connect(Uri.parse(url));
      _wsSub = _ws!.stream.listen(
        _onWsMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
      _ws!.sink.add(jsonEncode({'type': 'auth', 'token': token}));
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onWsMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! Map<String, dynamic>) return;
      final type = (decoded['type'] as String? ?? '').toLowerCase();
      if (type == 'auth_ok' || type == 'authok') {
        _wsConnected = true;
        if (!_wsReadyController.isClosed) _wsReadyController.add(true);
        return;
      }
      if (type == 'message_delivered') {
        final payload = decoded['message'];
        if (payload is Map<String, dynamic>) {
          final convId = decoded['conversationId']?.toString() ?? payload['conversationId']?.toString();
          final msg = UcgChatMessage.fromJson(
            {
              ...payload,
              if (convId != null && convId.isNotEmpty) 'conversationId': convId,
            },
            currentUserId: _userIdGetter(),
          );
          if (!_messageController.isClosed) _messageController.add(msg);
        }
        return;
      }
      if (type == 'message' || type == 'chat_message') {
        final payload = decoded['data'] ?? decoded['message'] ?? decoded;
        if (payload is Map<String, dynamic>) {
          final msg = UcgChatMessage.fromJson(payload, currentUserId: _userIdGetter());
          if (!_messageController.isClosed) _messageController.add(msg);
        }
        return;
      }
      if (type == 'comment_notification') {
        if (!_notificationController.isClosed) _notificationController.add(null);
      }
    } catch (_) {}
  }

  void _tearDownWs() {
    _wsConnected = false;
    if (!_wsReadyController.isClosed) _wsReadyController.add(false);
    _wsSub?.cancel();
    _wsSub = null;
    _ws?.sink.close();
    _ws = null;
  }

  void _scheduleReconnect() {
    _tearDownWs();
    if (!_shouldStayConnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      unawaited(connectChatWs());
    });
  }

  Future<void> sendChatWs(Map<String, dynamic> payload) async {
    if (_ws == null) await connectChatWs();
    _ws?.sink.add(jsonEncode(payload));
  }

  Future<UcgProfile?> fetchMyProfile() async {
    final data = await _api.get('/profile/me');
    return data == null ? null : UcgProfile.fromJson(data);
  }

  Future<UcgProfile?> fetchProfile(
    String userId, {
    bool withAuthorization = true,
  }) async {
    final data = await _api.get(
      '/profile/$userId',
      withAuthorization: withAuthorization,
    );
    return data == null ? null : UcgProfile.fromJson(data);
  }

  Future<UcgProfile> updateMyProfile(UcgProfile profile) async {
    final data = await _api.put('/profile/me', profile.toJson());
    return UcgProfile.fromJson(data ?? profile.toJson());
  }

  Future<UcgPagedPosts> fetchRecommendedFeed({required int page}) async {
    final data = await _api.get(
      '/feed/recommend',
      query: UcgApiClient.pageQuery(page: page, pageSize: kUcgPageSize),
    );
    return parsePagedPosts(data, publicFeedOnly: true);
  }

  Future<UcgPagedPosts> fetchFollowingFeed({required int page}) async {
    final data = await _api.get(
      '/feed/following',
      query: UcgApiClient.pageQuery(page: page, pageSize: kUcgPageSize),
    );
    return parsePagedPosts(data, publicFeedOnly: true);
  }

  Future<UcgPagedPosts> fetchMyPosts({required int page}) async {
    final data = await _api.get(
      '/posts/mine',
      query: UcgApiClient.pageQuery(page: page, pageSize: kUcgPageSize),
    );
    return parsePagedPosts(data);
  }

  Future<UcgPost> fetchPost(String postId) async {
    final data = await _api.get('/posts/$postId');
    if (data == null) {
      throw StateError('帖子不存在');
    }
    return UcgPost.fromJson(data);
  }

  Future<UcgPagedCommentNotifications> fetchCommentNotifications({
    required int page,
  }) async {
    final data = await _api.get(
      '/notifications/comments',
      query: UcgApiClient.pageQuery(page: page, pageSize: kUcgPageSize),
    );
    final raw = data?['list'] ?? data?['items'];
    final items = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(UcgCommentNotification.fromJson).toList()
        : <UcgCommentNotification>[];
    return UcgPagedCommentNotifications(
      items: items,
      page: (data?['page'] as num?)?.toInt() ?? page,
      pageSize: (data?['pageSize'] as num?)?.toInt() ?? kUcgPageSize,
      total: (data?['total'] as num?)?.toInt() ?? items.length,
      unreadCount: (data?['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markNotificationsRead({List<String>? ids, bool all = false}) async {
    final body = <String, dynamic>{
      if (all) 'all': true,
      if (!all && ids != null && ids.isNotEmpty)
        'ids': ids.map((id) => int.tryParse(id) ?? id).toList(),
    };
    await _api.post('/notifications/comments/read', body);
  }

  Future<void> deletePost(String postId) async {
    await _api.delete('/posts/$postId');
  }

  Future<UcgPost> createPost({
    required String text,
    List<String> imageKeys = const [],
    String? videoKey,
  }) async {
    final mediaType = videoKey != null && videoKey.isNotEmpty
        ? 2
        : (imageKeys.isNotEmpty ? 1 : 0);
    final media = <Map<String, dynamic>>[];
    var sort = 0;
    for (final key in imageKeys) {
      media.add({'objectKey': key, 'mediaKind': 1, 'sortOrder': sort++});
    }
    if (videoKey != null && videoKey.isNotEmpty) {
      media.add({'objectKey': videoKey, 'mediaKind': 2, 'sortOrder': 0});
    }
    final body = <String, dynamic>{
      'content': text,
      'mediaType': mediaType,
      'submit': true,
      if (media.isNotEmpty) 'media': media,
    };
    final data = await _api.post('/posts', body);
    return UcgPost.fromJson(data ?? body);
  }

  Future<UcgPresignResult> presignMedia({
    required bool isVideo,
    required String fileName,
  }) async {
    final data = await _api.post(
      '/media/presign',
      UcgPresignRequest.fromFileName(fileName, isVideo: isVideo).toJson(),
    );
    return UcgPresignResult.fromJson(data ?? {});
  }

  /// Web 经 gateway 同域代理上传，规避 OSS 直传 CORS 预检 403。
  Future<UcgUploadResult> uploadMediaViaGateway({
    required bool isVideo,
    required String fileName,
    required List<int> bytes,
  }) async {
    final req = UcgPresignRequest.fromFileName(fileName, isVideo: isVideo);
    final data = await _api.postMultipart(
      '/media/upload',
      fields: {
        'mediaKind': '${req.mediaKind}',
        'extension': req.extension,
      },
      fileField: 'file',
      fileName: fileName,
      bytes: bytes,
    );
    final objectKey = data?['objectKey'] as String? ?? '';
    if (objectKey.isEmpty) {
      throw const FormatException('upload 响应缺少 objectKey');
    }
    return UcgUploadResult(
      objectKey: objectKey,
      cdnUrl: data?['cdnUrl'] as String?,
    );
  }

  Future<UcgUploadResult> uploadMediaBytes({
    required bool isVideo,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (kIsWeb) {
      return uploadMediaViaGateway(
        isVideo: isVideo,
        fileName: fileName,
        bytes: bytes,
      );
    }
    final presign = await presignMedia(isVideo: isVideo, fileName: fileName);
    await uploadToPresignedUrl(
      uploadUrl: presign.uploadUrl,
      bytes: bytes,
      contentType: presign.headers['Content-Type'] ?? contentType,
      extraHeaders: presign.headers,
    );
    return UcgUploadResult(objectKey: presign.objectKey, cdnUrl: presign.cdnUrl);
  }

  Future<void> uploadToPresignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    Map<String, String> extraHeaders = const {},
  }) async {
    final headers = <String, String>{...extraHeaders};
    headers.putIfAbsent('Content-Type', () => contentType);
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: headers,
      body: bytes,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('上传失败(${res.statusCode})');
    }
  }

  Future<void> likePost(String postId) async {
    await _api.post('/posts/$postId/like', {});
  }

  Future<void> unlikePost(String postId) async {
    await _api.delete('/posts/$postId/like');
  }

  Future<List<UcgLiker>> fetchPostLikes(String postId) async {
    const pageSize = 50;
    var page = 1;
    final all = <UcgLiker>[];
    var total = 0;
    while (true) {
      final data = await _api.get(
        '/posts/$postId/likes',
        query: UcgApiClient.pageQuery(page: page, pageSize: pageSize),
      );
      total = (data?['total'] as num?)?.toInt() ?? 0;
      final raw = data?['list'] ?? data?['items'];
      if (raw is! List) break;
      final batch = raw.whereType<Map<String, dynamic>>().map(UcgLiker.fromJson).toList();
      all.addAll(batch);
      if (batch.isEmpty || all.length >= total) break;
      page++;
    }
    return all;
  }

  Future<List<UcgComment>> fetchComments(String postId) async {
    final data = await _api.get('/posts/$postId/comments');
    final raw = data?['list'] ?? data?['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => UcgComment.fromJson(e, currentUserId: _userIdGetter()))
        .toList();
  }

  Future<UcgComment> addComment(String postId, String text) async {
    final data = await _api.post('/posts/$postId/comments', {'content': text});
    return UcgComment.fromJson(
      data ?? {'content': text, 'postId': postId},
      currentUserId: _userIdGetter(),
    );
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/comments/$commentId');
  }

  Future<void> followUser(String userId) async {
    await _api.post('/follow/$userId', {});
  }

  Future<void> unfollowUser(String userId) async {
    await _api.delete('/follow/$userId');
  }

  Future<List<UcgProfile>> fetchFollowingList() async {
    final data = await _api.get('/follow/following');
    final raw = data?['list'] ?? data?['items'];
    if (raw is! List) return const [];
    final profiles = <UcgProfile>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        profiles.add(UcgProfile.fromJson(item));
        continue;
      }
      final wxId = item?.toString() ?? '';
      if (wxId.isEmpty) continue;
      final profile = await fetchProfile(wxId);
      if (profile != null) profiles.add(profile);
    }
    return profiles;
  }

  Future<List<UcgConversation>> fetchConversations() async {
    final data = await _api.get('/conversations');
    final raw = data?['list'] ?? data?['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(UcgConversation.fromJson).toList();
  }

  /// 补全会话对方昵称/头像（与聊天页 `_ensurePeerProfile` 一致：缺字段时 `GET /profile/{peerWxId}`）。
  Future<List<UcgConversation>> enrichConversationsWithPeerProfiles(
    List<UcgConversation> list,
  ) async {
    final selfId = _userIdGetter();
    final loggedIn = selfId != null && selfId.isNotEmpty;
    final profileCache = <String, UcgProfile?>{};
    final out = <UcgConversation>[];

    for (final c in list) {
      if (c.peerId.isEmpty || c.peerId == selfId) {
        out.add(c);
        continue;
      }
      final needsNickname = c.peerNickname.trim().isEmpty;
      final needsAvatar = c.peerAvatarThumbnailUrl == null;
      if (!needsNickname && !needsAvatar) {
        out.add(c);
        continue;
      }
      UcgProfile? profile;
      if (profileCache.containsKey(c.peerId)) {
        profile = profileCache[c.peerId];
      } else {
        try {
          profile = await fetchProfile(c.peerId, withAuthorization: loggedIn);
        } catch (_) {
          profile = null;
        }
        profileCache[c.peerId] = profile;
      }
      if (profile == null) {
        out.add(c);
        continue;
      }
      out.add(c.copyWith(
        peerNickname: needsNickname && profile.nickname.trim().isNotEmpty
            ? profile.nickname
            : c.peerNickname,
        peerAvatarKey: needsAvatar && profile.avatarKey != null
            ? profile.avatarKey
            : c.peerAvatarKey,
        peerAvatarCdnUrl: needsAvatar && profile.avatarUrl != null
            ? profile.avatarUrl
            : c.peerAvatarCdnUrl,
        peerAvatarThumbnailCdnUrl: needsAvatar && profile.avatarThumbnailUrl != null
            ? profile.avatarThumbnailUrl
            : c.peerAvatarThumbnailCdnUrl,
      ));
    }
    return out;
  }

  Future<UcgConversation> createConversation(String peerWxId) async {
    final wxIdNum = int.tryParse(peerWxId);
    final body = <String, dynamic>{
      'targetWxId': wxIdNum ?? peerWxId,
    };
    final data = await _api.post('/conversations', body);
    return UcgConversation.fromJson(data ?? {'peerWxId': peerWxId});
  }

  Future<List<UcgChatMessage>> fetchChatHistory(String conversationId) async {
    final data = await _api.get('/conversations/$conversationId/messages');
    final raw = data?['list'] ?? data?['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => UcgChatMessage.fromJson(e, currentUserId: _userIdGetter()))
        .toList();
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String peerId,
    required String text,
  }) async {
    await sendChatMessage(
      conversationId: conversationId,
      text: text,
    );
  }

  Future<void> sendChatMessage({
    required String conversationId,
    String text = '',
    String? imageKey,
    String? videoKey,
  }) async {
    final convId = int.tryParse(conversationId) ?? conversationId;
    await sendChatWs({
      'type': 'message',
      'conversationId': convId,
      'content': text,
      if (imageKey != null && imageKey.isNotEmpty) 'imageKey': imageKey,
      if (videoKey != null && videoKey.isNotEmpty) 'videoKey': videoKey,
      'clientMsgId': 'client-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    await _api.delete('/conversations/$conversationId');
  }

  Future<void> pinConversation(String conversationId, {required bool pinned}) async {
    await _api.put('/conversations/$conversationId/pin', {'pinned': pinned});
  }

  Future<void> markConversationRead(
    String conversationId, {
    String? lastMsgId,
  }) async {
    final body = <String, dynamic>{};
    if (lastMsgId != null && lastMsgId.isNotEmpty) {
      final id = int.tryParse(lastMsgId);
      body['lastMsgId'] = id ?? lastMsgId;
    }
    await _api.post('/conversations/$conversationId/read', body);
  }
}
