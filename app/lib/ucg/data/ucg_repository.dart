import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../api/ai_quota_codes.dart';
import '../../config/env.dart';
import '../../network/resilient_websocket_client.dart';
import '../../network/ws_auth_error_handler.dart';
import '../../network/ws_connection_config.dart';
import '../../network/ws_connection_phase.dart';
import '../../providers/ai_quota_dialog_bus.dart';
import '../../session/token_expiry.dart';
import 'ucg_api_client.dart';
import 'ucg_force_models.dart';
import 'ucg_models.dart';

import 'ucg_presign.dart';

typedef UcgUserIdGetter = String? Function();
typedef UcgWsErrorToast = void Function(String message);

/// UCG HTTP + 聊天 WebSocket（经 gateway `/ucg/app/ws/chat`）。
class UcgRepository {
  UcgRepository({
    required UcgApiClient api,
    required Ref ref,
    required UcgUserIdGetter userIdGetter,
    required String? Function() accessTokenGetter,
    required bool Function() isLoggedInGetter,
    required Future<String?> Function() prepareAccessToken,
    UcgWsErrorToast? onWsErrorToast,
  })  : _api = api,
        _ref = ref,
        _userIdGetter = userIdGetter,
        _accessTokenGetter = accessTokenGetter,
        _isLoggedInGetter = isLoggedInGetter,
        _prepareAccessToken = prepareAccessToken,
        _onWsErrorToast = onWsErrorToast {
    _wsClient = ResilientWebSocketClient(
      WsConnectionConfig(
        url: AppEnv.wsUcgChatUrlEffective,
        channelLabel: 'ucg-chat',
        shouldConnect: () async {
          if (AppEnv.wsUcgChatUrlEffective.isEmpty) return false;
          if (!_isLoggedInGetter()) return false;
          final token = _accessTokenGetter();
          if (token == null || token.isEmpty) return false;
          return isUcgWxAccountBound(readJwtWxId(token));
        },
        prepareToken: () async {
          final token = await _prepareAccessToken();
          if (token == null || token.isEmpty) return null;
          return WsConnectContext(accessToken: token);
        },
        buildAuthFrame: (ctx) => {'type': 'auth', 'token': ctx.accessToken},
        onApplicationFrame: _onChatApplicationFrame,
        onErrorFrame: _onChatWsError,
      ),
    );
    _wsClient.readyStream.listen((ready) {
      _wsConnected = ready;
      if (!_wsReadyController.isClosed) _wsReadyController.add(ready);
    });
  }

  final UcgApiClient _api;
  final Ref _ref;
  final UcgUserIdGetter _userIdGetter;
  final String? Function() _accessTokenGetter;
  final bool Function() _isLoggedInGetter;
  final Future<String?> Function() _prepareAccessToken;
  final UcgWsErrorToast? _onWsErrorToast;

  bool get _withAuthForPublicRead => _isLoggedInGetter();

  late final ResilientWebSocketClient _wsClient;
  var _wsConnected = false;
  final _messageController = StreamController<UcgChatMessage>.broadcast();
  final _wsReadyController = StreamController<bool>.broadcast();
  final _notificationController = StreamController<void>.broadcast();
  final _messageAckController = StreamController<String>.broadcast();
  final _auditFailedController = StreamController<String>.broadcast();

  Stream<UcgChatMessage> get incomingMessages => _messageController.stream;
  Stream<bool> get wsReadyStream => _wsReadyController.stream;
  Stream<void> get notificationEvents => _notificationController.stream;
  Stream<String> get messageAckClientIds => _messageAckController.stream;
  Stream<String> get auditFailedClientIds => _auditFailedController.stream;
  bool get isWsConnected => _wsConnected;
  WsConnectionPhase get chatWsPhase => _wsClient.phase;

  Future<({bool ready, WsConnectionPhase phase, int elapsedMs, String detail})>
      waitForChatWebSocketReady({
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _wsClient.waitForReadyOrTerminal(timeout: timeout);

  void dispose() {
    _wsClient.dispose();
    _messageController.close();
    _wsReadyController.close();
    _notificationController.close();
    _messageAckController.close();
    _auditFailedController.close();
  }

  void setWsConnectionDesired(bool desired) => _wsClient.setConnectionDesired(desired);

  Future<void> reconnectChatWebSocket({bool resetStrike = false}) async {
    _wsClient.setConnectionDesired(true);
    await _wsClient.reconnect(resetStrike: resetStrike);
  }

  void onAppLifecycleResumed() => _wsClient.onAppLifecycleResumed();

  Future<bool> _onChatWsError(Map<String, dynamic> decoded) async {
    final code = parseWsErrorBusinessCode(decoded);
    if (code != null && isAiQuotaBusinessCode(code)) {
      final result = await handleWsAuthOrQuotaError(
        _ref,
        decoded,
        onQuotaDialog: (c) => _ref.requestAiQuotaDialog(c),
      );
      if (result.requestLoginDialog) {
        _ref.requestAiQuotaDialog(kAiCodeNotLoggedIn);
      }
      return result.scheduleReconnect;
    }
    final message = decoded['message']?.toString().trim() ?? '';
    _onWsErrorToast?.call(message.isNotEmpty ? message : '操作失败');
    // 业务 error（如发送失败）不断连、不重连；已连接时 ResilientWebSocketClient 会保持通道。
    return false;
  }

  Future<void> connectChatWs() async {
    _wsClient.setConnectionDesired(true);
  }

  void _onChatApplicationFrame(Map<String, dynamic> decoded) {
    final type = (decoded['type'] as String? ?? '').toLowerCase();
    if (type == 'message_ack') {
      final clientMsgId = decoded['clientMsgId']?.toString() ?? '';
      if (clientMsgId.isNotEmpty && !_messageAckController.isClosed) {
        _messageAckController.add(clientMsgId);
      }
      return;
    }
    if (type == 'audit_failed') {
      final clientMsgId = decoded['clientMsgId']?.toString() ?? '';
      if (clientMsgId.isNotEmpty && !_auditFailedController.isClosed) {
        _auditFailedController.add(clientMsgId);
      }
      return;
    }
    if (type == 'message_delivered') {
      final payload = decoded['message'];
      if (payload is Map<String, dynamic>) {
        final convId =
            decoded['conversationId']?.toString() ?? payload['conversationId']?.toString();
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
  }

  Future<void> sendChatWs(Map<String, dynamic> payload) async {
    if (!_wsClient.isReady) {
      _wsClient.setConnectionDesired(true);
    }
    _wsClient.sendJson(payload);
  }

  Future<UcgProfile?> fetchMyProfile() async {
    final data = await _api.get('/profile/me');
    return data == null ? null : UcgProfile.fromJson(data);
  }

  /// GET `/ucg/app/api/force/ledger`：当前用户原力积分与流水。
  Future<UcgForceLedgerPage> fetchForceLedger({
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/force/ledger',
      query: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    if (data == null) {
      throw StateError('原力流水查询失败');
    }
    return UcgForceLedgerPage.fromJson(data);
  }

  Future<UcgProfile?> fetchProfile(
    String userId, {
    bool? withAuthorization,
  }) async {
    final data = await _api.get(
      '/profile/$userId',
      withAuthorization: withAuthorization ?? _withAuthForPublicRead,
    );
    return data == null ? null : UcgProfile.fromJson(data);
  }

  Future<UcgProfile> updateMyProfile(UcgProfile profile) async {
    final data = await _api.put('/profile/me', profile.toJson());
    return UcgProfile.fromJson(data ?? profile.toJson());
  }

  // 推荐广场帖子接口（cursor + 可选坐标）
  Future<UcgCursorFeedPage> fetchRecommendedFeed({
    String? cursor,
    double? lat,
    double? lng,
  }) async {
    final query = <String, String>{
      'pageSize': '$kUcgPageSize',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      if (cursor == null || cursor.isEmpty) ...{
        if (lat != null) 'lat': lat.toString(),
        if (lng != null) 'lng': lng.toString(),
      },
    };
    final data = await _api.get(
      '/feed/recommend',
      query: query,
      withAuthorization: _withAuthForPublicRead,
      timeout: const Duration(seconds: 45),
    );
    return parseCursorFeed(data, publicFeedOnly: true);
  }

  Future<UcgPagedPosts> fetchFollowingFeed({
    required int page,
    double? lat,
    double? lng,
  }) async {
    final query = <String, String>{
      ...UcgApiClient.pageQuery(page: page, pageSize: kUcgPageSize),
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
    };
    final data = await _api.get(
      '/feed/following',
      query: query,
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

  Future<UcgPagedPosts> fetchUserPosts({
    required String wxId,
    required int page,
  }) async {
    final data = await _api.get(
      '/posts/user/$wxId',
      query: UcgApiClient.pageQuery(page: page, pageSize: kUcgPageSize),
      withAuthorization: _withAuthForPublicRead,
    );
    return parsePagedPosts(data, publicFeedOnly: true);
  }

  Future<UcgPost> fetchPost(String postId, {double? lat, double? lng}) async {
    final query = <String, String>{
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
    };
    final data = await _api.get(
      '/posts/$postId',
      query: query.isEmpty ? null : query,
      withAuthorization: _withAuthForPublicRead,
    );
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
    double? lat,
    double? lng,
    String? debateLeft,
    String? debateRight,
  }) async {
    final left = debateLeft?.trim() ?? '';
    final right = debateRight?.trim() ?? '';
    if (left.isNotEmpty != right.isNotEmpty) {
      throw StateError('请补全另一方立场');
    }
    if (left.isNotEmpty && left.runes.length > 5) {
      throw StateError('立场标签最多 5 字');
    }
    if (right.isNotEmpty && right.runes.length > 5) {
      throw StateError('立场标签最多 5 字');
    }
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
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (left.isNotEmpty && right.isNotEmpty) ...{
        'debateLeft': left,
        'debateRight': right,
      },
    };
    final data = await _api.post('/posts', body);
    return UcgPost.fromJson(data ?? body);
  }

  @Deprecated('Use createPost with debateLeft/debateRight')
  Future<UcgPost> createDebatePost({
    required String topic,
    required String debateLeft,
    required String debateRight,
  }) =>
      createPost(
        text: topic,
        debateLeft: debateLeft,
        debateRight: debateRight,
      );

  Future<UcgPost> updatePost({
    required String postId,
    required String text,
    List<String> imageKeys = const [],
    String? videoKey,
    double? lat,
    double? lng,
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
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    final data = await _api.put('/posts/$postId', body);
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

  Future<UcgResolveResult> resolveMedia({
    required String contentHash,
    required String transformVersion,
    required bool isVideo,
  }) async {
    final data = await _api.post('/media/resolve', {
      'contentHash': contentHash,
      'transformVersion': transformVersion,
      'mediaKind': isVideo ? 2 : 1,
    });
    return UcgResolveResult.fromJson(data ?? const {});
  }

  Future<UcgUploadResult> registerMedia({
    required String objectKey,
    required String contentHash,
    required String transformVersion,
    required bool isVideo,
    required bool dedupHit,
  }) async {
    final data = await _api.post(
      '/media/register',
      UcgRegisterRequest(
        objectKey: objectKey,
        contentHash: contentHash,
        transformVersion: transformVersion,
        mediaKind: isVideo ? 2 : 1,
        dedupHit: dedupHit,
      ).toJson(),
    );
    final key = data?['objectKey'] as String? ?? objectKey;
    if (key.isEmpty) {
      throw const FormatException('register 响应缺少 objectKey');
    }
    return UcgUploadResult(objectKey: key, cdnUrl: data?['cdnUrl'] as String?);
  }

  /// 删除已上传但未发帖的 OSS 媒体（孤儿清理）。
  Future<({List<String> deleted, List<String> skipped})> deleteMedia({
    required List<String> objectKeys,
  }) async {
    if (objectKeys.isEmpty) {
      return (deleted: <String>[], skipped: <String>[]);
    }
    final data = await _api.post('/media/delete', {'objectKeys': objectKeys});
    final deleted = <String>[];
    final skipped = <String>[];
    final rawDeleted = data?['deleted'];
    if (rawDeleted is List) {
      for (final e in rawDeleted) {
        if (e is String && e.isNotEmpty) deleted.add(e);
      }
    }
    final rawSkipped = data?['skipped'];
    if (rawSkipped is List) {
      for (final e in rawSkipped) {
        if (e is String && e.isNotEmpty) skipped.add(e);
      }
    }
    return (deleted: List<String>.from(deleted), skipped: List<String>.from(skipped));
  }

  /// AI 润笔正文（需已上传图片 objectKeys）。
  Future<({String polishedText, bool quotaDegraded})> polishPost({
    required List<String> imageKeys,
    String? text,
  }) async {
    final body = <String, dynamic>{
      'imageKeys': imageKeys,
      if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
    };
    final data = await _api.post('/posts/polish', body);
    final polished = data?['polishedText'] as String? ?? '';
    if (polished.trim().isEmpty) {
      throw const FormatException('润笔响应缺少 polishedText');
    }
    final quotaDegraded = data?['quotaDegraded'] == true;
    return (polishedText: polished.trim(), quotaDegraded: quotaDegraded);
  }

  /// Web 经 gateway 同域代理上传，规避 OSS 直传 CORS 预检 403（不写 ownership）。
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
    required String contentHash,
    required String transformVersion,
  }) async {
    final resolved = await resolveMedia(
      contentHash: contentHash,
      transformVersion: transformVersion,
      isVideo: isVideo,
    );

    if (resolved.hit) {
      final objectKey = resolved.objectKey;
      if (objectKey == null || objectKey.isEmpty) {
        throw const FormatException('resolve hit 响应缺少 objectKey');
      }
      return registerMedia(
        objectKey: objectKey,
        contentHash: contentHash,
        transformVersion: transformVersion,
        isVideo: isVideo,
        dedupHit: true,
      );
    }

    if (kIsWeb) {
      final uploaded = await uploadMediaViaGateway(
        isVideo: isVideo,
        fileName: fileName,
        bytes: bytes,
      );
      return registerMedia(
        objectKey: uploaded.objectKey,
        contentHash: contentHash,
        transformVersion: transformVersion,
        isVideo: isVideo,
        dedupHit: false,
      );
    }

    final presign = await presignMedia(isVideo: isVideo, fileName: fileName);
    await uploadToPresignedUrl(
      uploadUrl: presign.uploadUrl,
      bytes: bytes,
      contentType: presign.headers['Content-Type'] ?? contentType,
      extraHeaders: presign.headers,
    );
    return registerMedia(
      objectKey: presign.objectKey,
      contentHash: contentHash,
      transformVersion: transformVersion,
      isVideo: isVideo,
      dedupHit: false,
    );
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

  Future<void> votePost(String postId, {required String side}) async {
    await _api.post('/posts/$postId/vote', {'side': side});
  }

  Future<void> likePost(String postId, {UcgPost? post}) async {
    if (post?.isDebate == true) return;
    await _api.post('/posts/$postId/like', {});
  }

  Future<void> unlikePost(String postId, {UcgPost? post}) async {
    if (post?.isDebate == true) return;
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

  Future<UcgCommentsList> fetchComments(String postId) async {
    final data = await _api.get('/posts/$postId/comments');
    final raw = data?['list'] ?? data?['items'];
    final items = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map((e) => UcgComment.fromJson(e, currentUserId: _userIdGetter()))
            .toList()
        : <UcgComment>[];
    return UcgCommentsList(
      items: items,
      total: (data?['total'] as num?)?.toInt() ?? items.length,
      truncated: data?['truncated'] == true,
    );
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

  Future<UcgPagedConversations> fetchConversations({required int page}) async {
    final data = await _api.get(
      '/conversations',
      query: UcgApiClient.pageQuery(page: page, pageSize: kUcgPageSize),
    );
    final raw = data?['list'] ?? data?['items'];
    final items = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(UcgConversation.fromJson).toList()
        : <UcgConversation>[];
    return UcgPagedConversations(
      items: items,
      page: (data?['page'] as num?)?.toInt() ?? page,
      pageSize: (data?['pageSize'] as num?)?.toInt() ?? kUcgPageSize,
      total: (data?['total'] as num?)?.toInt() ?? items.length,
    );
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
      clientMsgId: 'client-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
    );
  }

  Future<void> sendChatMessage({
    required String conversationId,
    required String clientMsgId,
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
      'clientMsgId': clientMsgId,
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
