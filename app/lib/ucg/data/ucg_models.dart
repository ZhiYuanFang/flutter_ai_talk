import 'ucg_media_url.dart';

const kUcgPageSize = 20;

enum UcgPostStatus {
  draft,
  pendingAudit,
  published,
  rejected;

  static UcgPostStatus fromApi(dynamic raw) {
    if (raw is int || raw is num) {
      return switch (raw is num ? raw.toInt() : raw) {
        0 => UcgPostStatus.draft,
        1 => UcgPostStatus.pendingAudit,
        2 => UcgPostStatus.published,
        3 => UcgPostStatus.rejected,
        _ => UcgPostStatus.published,
      };
    }
    final s = raw?.toString();
    return switch (s) {
      'draft' || '0' => UcgPostStatus.draft,
      'pending_audit' || '1' => UcgPostStatus.pendingAudit,
      'published' || '2' => UcgPostStatus.published,
      'rejected' || '3' => UcgPostStatus.rejected,
      _ => UcgPostStatus.published,
    };
  }

  String get apiValue => switch (this) {
        UcgPostStatus.draft => 'draft',
        UcgPostStatus.pendingAudit => 'pending_audit',
        UcgPostStatus.published => 'published',
        UcgPostStatus.rejected => 'rejected',
      };
}

class UcgProfile {
  const UcgProfile({
    required this.userId,
    required this.nickname,
    this.avatarKey,
    this.avatarCdnUrl,
    this.avatarThumbnailCdnUrl,
    this.bio = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.isFollowing = false,
    this.ipLocation,
  });

  final String userId;
  final String nickname;
  final String? avatarKey;
  final String? avatarCdnUrl;
  final String? avatarThumbnailCdnUrl;
  final String bio;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isFollowing;
  final String? ipLocation;

  String get ipLocationDisplay {
    final loc = ipLocation?.trim();
    if (loc != null && loc.isNotEmpty) return 'IP属地：$loc';
    return 'IP属地：未知';
  }

  String? get avatarUrl {
    final fromApi = avatarCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    if (avatarKey == null || avatarKey!.isEmpty) return null;
    return UcgMediaUrl.objectKeyToCdn(avatarKey!);
  }

  /// 列表 surface 缩略图头像（Feed、消息、会话等）。
  String? get avatarThumbnailUrl {
    final fromApi = avatarThumbnailCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return avatarUrl;
  }

  factory UcgProfile.fromJson(Map<String, dynamic> json) {
    return UcgProfile(
      userId: json['wxId']?.toString() ??
          json['userId'] as String? ??
          json['id']?.toString() ??
          '',
      nickname: json['nickname'] as String? ?? '',
      avatarKey: json['avatarKey'] as String? ?? json['avatar'] as String?,
      avatarCdnUrl: json['avatarUrl'] as String?,
      avatarThumbnailCdnUrl: json['avatarThumbnailUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      followerCount: _int(json['followerCount']),
      followingCount: _int(json['followingCount']),
      postCount: _int(json['postCount']),
      isFollowing: json['isFollowing'] == true,
      ipLocation: _nullableString(json['ipLocation'] ?? json['location'] ?? json['region']),
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        if (avatarKey != null) 'avatarKey': avatarKey,
        'bio': bio,
      };

  UcgProfile copyWith({
    String? nickname,
    String? avatarKey,
    String? avatarCdnUrl,
    String? avatarThumbnailCdnUrl,
    String? bio,
    int? followerCount,
    int? followingCount,
    int? postCount,
    bool? isFollowing,
    String? ipLocation,
  }) {
    return UcgProfile(
      userId: userId,
      nickname: nickname ?? this.nickname,
      avatarKey: avatarKey ?? this.avatarKey,
      avatarCdnUrl: avatarCdnUrl ?? this.avatarCdnUrl,
      avatarThumbnailCdnUrl: avatarThumbnailCdnUrl ?? this.avatarThumbnailCdnUrl,
      bio: bio ?? this.bio,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      isFollowing: isFollowing ?? this.isFollowing,
      ipLocation: ipLocation ?? this.ipLocation,
    );
  }
}

String? _nullableString(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

String? _mediaCdnAt(List<String> list, int index) {
  if (index < 0 || index >= list.length) return null;
  final s = list[index].trim();
  return s.isEmpty ? null : s;
}

class UcgPost {
  const UcgPost({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    this.authorAvatarKey,
    this.authorAvatarCdnUrl,
    this.authorAvatarThumbnailCdnUrl,
    this.authorBio = '',
    required this.text,
    this.imageKeys = const [],
    this.imageCdnUrls = const [],
    this.imageThumbKeys = const [],
    this.imageThumbCdnUrls = const [],
    this.videoKey,
    this.videoCdnUrl,
    this.videoThumbKey,
    this.videoThumbCdnUrl,
    this.videoWidth,
    this.videoHeight,
    required this.status,
    this.rejectReason,
    required this.createdAt,
    this.publishedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.ipLocation,
  });

  final String id;
  final String authorId;
  final String authorNickname;
  final String? authorAvatarKey;
  final String? authorAvatarCdnUrl;
  final String? authorAvatarThumbnailCdnUrl;
  final String authorBio;
  final String text;
  final List<String> imageKeys;
  final List<String> imageCdnUrls;
  final List<String> imageThumbKeys;
  final List<String> imageThumbCdnUrls;
  final String? videoKey;
  final String? videoCdnUrl;
  final String? videoThumbKey;
  final String? videoThumbCdnUrl;
  final int? videoWidth;
  final int? videoHeight;
  final UcgPostStatus status;
  final String? rejectReason;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final String? ipLocation;

  String get ipLocationDisplay {
    final loc = ipLocation?.trim();
    if (loc != null && loc.isNotEmpty) return loc;
    return '';
  }

  bool get isVideo => videoKey != null && videoKey!.isNotEmpty;

  String? get authorAvatarUrl {
    final fromApi = authorAvatarCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    if (authorAvatarKey == null || authorAvatarKey!.isEmpty) return null;
    return UcgMediaUrl.objectKeyToCdn(authorAvatarKey!);
  }

  String? get authorAvatarThumbnailUrl {
    final fromApi = authorAvatarThumbnailCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return authorAvatarUrl;
  }

  List<String> get imageUrls => [
        for (var i = 0; i < imageKeys.length; i++)
          UcgMediaUrl.fullUrl(
            objectKey: imageKeys[i],
            cdnUrl: _mediaCdnAt(imageCdnUrls, i),
          ),
      ].where((u) => u.isNotEmpty).toList();

  List<String> get imageThumbnailUrls => [
        for (var i = 0; i < imageKeys.length; i++)
          UcgMediaUrl.thumbnailUrl(
            objectKey: imageKeys[i],
            cdnUrl: _mediaCdnAt(imageCdnUrls, i),
            apiThumbnailUrl: _mediaCdnAt(imageThumbCdnUrls, i),
            apiThumbKey: _mediaCdnAt(imageThumbKeys, i),
          ),
      ].where((u) => u.isNotEmpty).toList();

  String? get videoUrl {
    if (videoKey == null || videoKey!.isEmpty) return null;
    return UcgMediaUrl.fullUrl(objectKey: videoKey!, cdnUrl: videoCdnUrl);
  }

  /// 视频封面由客户端首帧提取，不读服务端 thumb。
  String? get videoThumbnailUrl => null;

  bool get isVisibleInPublicFeed => status == UcgPostStatus.published;

  /// 已发布帖子展示发布时间，其余状态展示创建时间。
  DateTime get displayAt =>
      (status == UcgPostStatus.published && publishedAt != null)
          ? publishedAt!
          : createdAt;

  UcgPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    String? authorBio,
    String? authorNickname,
  }) {
    return UcgPost(
      id: id,
      authorId: authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      authorAvatarKey: authorAvatarKey,
      authorAvatarCdnUrl: authorAvatarCdnUrl,
      authorAvatarThumbnailCdnUrl: authorAvatarThumbnailCdnUrl,
      authorBio: authorBio ?? this.authorBio,
      text: text,
      imageKeys: imageKeys,
      imageCdnUrls: imageCdnUrls,
      imageThumbKeys: imageThumbKeys,
      imageThumbCdnUrls: imageThumbCdnUrls,
      videoKey: videoKey,
      videoCdnUrl: videoCdnUrl,
      videoThumbKey: videoThumbKey,
      videoThumbCdnUrl: videoThumbCdnUrl,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      status: status,
      rejectReason: rejectReason,
      createdAt: createdAt,
      publishedAt: publishedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory UcgPost.fromJson(Map<String, dynamic> json) {
    final keys = <String>[];
    final cdnUrls = <String>[];
    final thumbKeys = <String>[];
    final thumbCdnUrls = <String>[];
    String? videoKey;
    String? videoCdnUrl;
    String? videoThumbKey;
    String? videoThumbCdnUrl;
    int? videoWidth;
    int? videoHeight;
    final mediaRaw = json['media'];
    if (mediaRaw is List) {
      for (final item in mediaRaw) {
        if (item is! Map<String, dynamic>) continue;
        final key = item['objectKey'] as String? ?? '';
        if (key.isEmpty) continue;
        final cdn = item['cdnUrl'] as String? ?? '';
        final thumbKey = item['thumbKey'] as String? ?? item['thumbnailKey'] as String?;
        final thumbUrl = item['thumbnailUrl'] as String? ?? item['thumbUrl'] as String?;
        final kind = _int(item['mediaKind']);
        if (kind == 2) {
          videoKey = key;
          videoCdnUrl = cdn.isNotEmpty ? cdn : null;
          videoThumbKey = thumbKey;
          videoThumbCdnUrl = thumbUrl;
          final w = _intOrNull(item['width']);
          final h = _intOrNull(item['height']);
          if (w != null && w > 0) videoWidth = w;
          if (h != null && h > 0) videoHeight = h;
        } else {
          keys.add(key);
          cdnUrls.add(cdn);
          thumbKeys.add(thumbKey ?? '');
          thumbCdnUrls.add(thumbUrl ?? '');
        }
      }
    } else {
      final imagesRaw = json['imageKeys'] ?? json['images'];
      if (imagesRaw is List) {
        for (final e in imagesRaw) {
          if (e is String && e.isNotEmpty) keys.add(e);
        }
      }
      videoKey = json['videoKey'] as String?;
    }
    final author = json['author'];
    var authorId = json['authorWxId']?.toString() ??
        json['authorId'] as String? ??
        json['userId']?.toString() ??
        '';
    var authorNickname = json['authorNickname'] as String? ?? json['nickname'] as String? ?? '';
    var authorAvatarKey = json['authorAvatarKey'] as String? ?? json['avatarKey'] as String?;
    var authorAvatarCdnUrl = json['authorAvatarUrl'] as String? ?? json['avatarUrl'] as String?;
    var authorAvatarThumbnailCdnUrl = json['authorAvatarThumbnailUrl'] as String?;
    var authorBio = json['authorBio'] as String? ?? '';
    if (author is Map<String, dynamic>) {
      authorId = author['wxId']?.toString() ?? authorId;
      authorNickname = author['nickname'] as String? ?? authorNickname;
      authorAvatarKey = author['avatarKey'] as String? ?? authorAvatarKey;
      authorAvatarCdnUrl = author['avatarUrl'] as String? ?? authorAvatarCdnUrl;
      authorAvatarThumbnailCdnUrl =
          author['avatarThumbnailUrl'] as String? ?? authorAvatarThumbnailCdnUrl;
      authorBio = author['bio'] as String? ?? authorBio;
    }
    authorBio = authorBio.trim();
    return UcgPost(
      id: json['id']?.toString() ?? json['postId']?.toString() ?? '',
      authorId: authorId,
      authorNickname: authorNickname,
      authorAvatarKey: authorAvatarKey,
      authorAvatarCdnUrl: authorAvatarCdnUrl,
      authorAvatarThumbnailCdnUrl: authorAvatarThumbnailCdnUrl,
      authorBio: authorBio,
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      imageKeys: keys,
      imageCdnUrls: cdnUrls,
      imageThumbKeys: thumbKeys,
      imageThumbCdnUrls: thumbCdnUrls,
      videoKey: videoKey,
      videoCdnUrl: videoCdnUrl,
      videoThumbKey: videoThumbKey,
      videoThumbCdnUrl: videoThumbCdnUrl,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      status: UcgPostStatus.fromApi(json['status']),
      rejectReason: json['rejectReason'] as String? ?? json['reason'] as String?,
      createdAt: _date(json['createdAt']),
      publishedAt: _dateOrNull(json['publishedAt']),
      likeCount: _int(json['likeCount']),
      commentCount: _int(json['commentCount']),
      likedByMe: json['likedByMe'] == true || json['liked'] == true,
      ipLocation: _nullableString(json['ipLocation'] ?? json['location'] ?? json['region']),
    );
  }
}

class UcgPagedPosts {
  const UcgPagedPosts({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<UcgPost> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore => page * pageSize < total;
}

class UcgPagedConversations {
  const UcgPagedConversations({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<UcgConversation> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore => page * pageSize < total;
}

class UcgCommentNotification {
  const UcgCommentNotification({
    required this.id,
    required this.type,
    required this.postId,
    required this.commentId,
    required this.actorId,
    required this.actorNickname,
    this.actorAvatarUrl,
    this.preview = '',
    this.postThumbUrl = '',
    this.postMediaKind = 0,
    this.read = false,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String postId;
  final String commentId;
  final String actorId;
  final String actorNickname;
  final String? actorAvatarUrl;
  final String preview;
  final String postThumbUrl;
  final int postMediaKind;
  final bool read;
  final DateTime createdAt;

  factory UcgCommentNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'];
    var actorId = json['actorWxId']?.toString() ?? '';
    var actorNickname = json['actorNickname'] as String? ?? '';
    String? actorAvatarUrl;
    if (actor is Map<String, dynamic>) {
      actorId = actor['wxId']?.toString() ?? actorId;
      actorNickname = actor['nickname'] as String? ?? actorNickname;
      actorAvatarUrl = actor['avatarUrl'] as String? ?? actor['avatarThumbnailUrl'] as String?;
    }
    return UcgCommentNotification(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      postId: json['postId']?.toString() ?? '',
      commentId: json['commentId']?.toString() ?? '',
      actorId: actorId,
      actorNickname: actorNickname,
      actorAvatarUrl: actorAvatarUrl,
      preview: json['preview'] as String? ?? '',
      postThumbUrl: json['postThumbUrl'] as String? ?? '',
      postMediaKind: _int(json['postMediaKind']),
      read: json['read'] == true,
      createdAt: _date(json['createdAt']),
    );
  }
}

class UcgPagedCommentNotifications {
  const UcgPagedCommentNotifications({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.unreadCount,
  });

  final List<UcgCommentNotification> items;
  final int page;
  final int pageSize;
  final int total;
  final int unreadCount;

  bool get hasMore => page * pageSize < total;
}

/// 帖子评论全量列表（服务端单次 GET，非分页）。
class UcgCommentsList {
  const UcgCommentsList({
    required this.items,
    required this.total,
    this.truncated = false,
  });

  final List<UcgComment> items;
  final int total;
  final bool truncated;
}

class UcgComment {
  const UcgComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorNickname,
    required this.text,
    required this.createdAt,
    this.isMine = false,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorNickname;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  UcgComment copyWith({
    String? authorNickname,
    String? text,
    bool? isMine,
  }) {
    return UcgComment(
      id: id,
      postId: postId,
      authorId: authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      text: text ?? this.text,
      createdAt: createdAt,
      isMine: isMine ?? this.isMine,
    );
  }

  factory UcgComment.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final author = json['author'];
    var authorId = json['authorWxId']?.toString() ??
        json['authorId'] as String? ??
        json['userId']?.toString() ??
        '';
    var authorNickname = json['authorNickname'] as String? ?? json['nickname'] as String? ?? '';
    if (author is Map<String, dynamic>) {
      authorId = author['wxId']?.toString() ?? authorId;
      authorNickname = author['nickname'] as String? ?? authorNickname;
    }
    return UcgComment(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      authorId: authorId,
      authorNickname: authorNickname,
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      createdAt: _date(json['createdAt']),
      isMine: currentUserId != null && authorId == currentUserId,
    );
  }
}

class UcgLiker {
  const UcgLiker({
    required this.wxId,
    required this.nickname,
    this.avatarKey,
    this.avatarCdnUrl,
    this.avatarThumbnailCdnUrl,
  });

  final String wxId;
  final String nickname;
  final String? avatarKey;
  final String? avatarCdnUrl;
  final String? avatarThumbnailCdnUrl;

  String? get avatarUrl {
    final fromApi = avatarCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    if (avatarKey == null || avatarKey!.isEmpty) return null;
    return UcgMediaUrl.objectKeyToCdn(avatarKey!);
  }

  String? get avatarThumbnailUrl {
    final fromApi = avatarThumbnailCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return avatarUrl;
  }

  factory UcgLiker.fromJson(Map<String, dynamic> json) {
    return UcgLiker(
      wxId: json['wxId']?.toString() ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarKey: json['avatarKey'] as String? ?? json['avatar'] as String?,
      avatarCdnUrl: json['avatarUrl'] as String? ?? json['avatarCdnUrl'] as String?,
      avatarThumbnailCdnUrl: json['avatarThumbnailUrl'] as String?,
    );
  }
}

class UcgConversation {
  const UcgConversation({
    required this.id,
    required this.peerId,
    required this.peerNickname,
    this.peerAvatarKey,
    this.peerAvatarCdnUrl,
    this.peerAvatarThumbnailCdnUrl,
    this.lastMessagePreview = '',
    this.lastMessageAt,
    this.unreadCount = 0,
    this.pinned = false,
  });

  final String id;
  final String peerId;
  final String peerNickname;
  final String? peerAvatarKey;
  final String? peerAvatarCdnUrl;
  final String? peerAvatarThumbnailCdnUrl;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool pinned;

  String? get peerAvatarUrl {
    final fromApi = peerAvatarCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    if (peerAvatarKey == null || peerAvatarKey!.isEmpty) return null;
    return UcgMediaUrl.objectKeyToCdn(peerAvatarKey!);
  }

  String? get peerAvatarThumbnailUrl {
    final fromApi = peerAvatarThumbnailCdnUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return peerAvatarUrl;
  }

  UcgConversation copyWith({
    int? unreadCount,
    bool? pinned,
    String? peerNickname,
    String? peerAvatarKey,
    String? peerAvatarCdnUrl,
    String? peerAvatarThumbnailCdnUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
  }) {
    return UcgConversation(
      id: id,
      peerId: peerId,
      peerNickname: peerNickname ?? this.peerNickname,
      peerAvatarKey: peerAvatarKey ?? this.peerAvatarKey,
      peerAvatarCdnUrl: peerAvatarCdnUrl ?? this.peerAvatarCdnUrl,
      peerAvatarThumbnailCdnUrl:
          peerAvatarThumbnailCdnUrl ?? this.peerAvatarThumbnailCdnUrl,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      pinned: pinned ?? this.pinned,
    );
  }

  factory UcgConversation.fromJson(Map<String, dynamic> json) {
    final pinnedRaw = json['pinned'];
    return UcgConversation(
      id: json['id']?.toString() ?? json['conversationId']?.toString() ?? '',
      peerId: json['peerWxId']?.toString() ??
          json['peerId'] as String? ??
          json['targetUserId']?.toString() ??
          '',
      peerNickname: json['peerNickname'] as String? ?? json['nickname'] as String? ?? '',
      peerAvatarKey: json['peerAvatarKey'] as String? ?? json['avatarKey'] as String?,
      peerAvatarCdnUrl: json['peerAvatarUrl'] as String?,
      peerAvatarThumbnailCdnUrl: json['peerAvatarThumbnailUrl'] as String?,
      lastMessagePreview: json['lastPreview'] as String? ??
          json['lastMessagePreview'] as String? ??
          json['preview'] as String? ??
          '',
      lastMessageAt: json['lastMessageAt'] != null
          ? _date(json['lastMessageAt'])
          : (json['updatedAt'] != null ? _date(json['updatedAt']) : null),
      unreadCount: _int(json['unreadCount']),
      pinned: pinnedRaw == true || pinnedRaw == 1,
    );
  }
}

enum UcgChatMessageStatus { pending, delivered, failed }

class UcgChatMessage {
  const UcgChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.clientMsgId,
    this.imageKey,
    this.videoKey,
    this.mediaCdnUrl,
    this.mediaThumbnailUrl,
    required this.createdAt,
    this.status = UcgChatMessageStatus.delivered,
    this.isMine = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? clientMsgId;
  final String? imageKey;
  final String? videoKey;
  final String? mediaCdnUrl;
  final String? mediaThumbnailUrl;
  final DateTime createdAt;
  final UcgChatMessageStatus status;
  final bool isMine;

  bool get hasImage => imageKey != null && imageKey!.isNotEmpty;
  bool get hasVideo => videoKey != null && videoKey!.isNotEmpty;
  bool get hasMedia => hasImage || hasVideo;

  String? get imageUrl {
    if (!hasImage) return null;
    return UcgMediaUrl.resolveUrl(objectKey: imageKey!, cdnUrl: mediaCdnUrl);
  }

  String? get imageThumbnailUrl {
    if (!hasImage) return null;
    final fromApi = mediaThumbnailUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return imageUrl;
  }

  String? get videoUrl {
    if (!hasVideo) return null;
    return UcgMediaUrl.resolveUrl(objectKey: videoKey!, cdnUrl: mediaCdnUrl);
  }

  factory UcgChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['senderWxId']?.toString() ??
        json['senderId'] as String? ??
        json['fromUserId']?.toString() ??
        '';
    return UcgChatMessage(
      id: json['id']?.toString() ?? json['messageId']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: senderId,
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      clientMsgId: json['clientMsgId']?.toString(),
      imageKey: json['imageKey'] as String?,
      videoKey: json['videoKey'] as String?,
      mediaCdnUrl: json['mediaCdnUrl'] as String?,
      mediaThumbnailUrl: json['mediaThumbnailUrl'] as String?,
      createdAt: _date(json['createdAt']),
      status: UcgChatMessageStatus.delivered,
      isMine: currentUserId != null && senderId == currentUserId,
    );
  }
}

class UcgComposeDraft {
  const UcgComposeDraft({
    this.text = '',
    this.imageKeys = const [],
    this.videoKey,
    this.editingPostId,
    this.updatedAt,
  });

  final String text;
  final List<String> imageKeys;
  final String? videoKey;
  final String? editingPostId;
  final DateTime? updatedAt;

  bool get isEmpty =>
      text.trim().isEmpty && imageKeys.isEmpty && (videoKey == null || videoKey!.isEmpty);

  Map<String, dynamic> toJson() => {
        'text': text,
        'imageKeys': imageKeys,
        if (videoKey != null) 'videoKey': videoKey,
        if (editingPostId != null) 'editingPostId': editingPostId,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory UcgComposeDraft.fromJson(Map<String, dynamic> json) {
    final keys = <String>[];
    final raw = json['imageKeys'];
    if (raw is List) {
      for (final e in raw) {
        if (e is String) keys.add(e);
      }
    }
    return UcgComposeDraft(
      text: json['text'] as String? ?? '',
      imageKeys: keys,
      videoKey: json['videoKey'] as String?,
      editingPostId: json['editingPostId'] as String?,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return 0;
}

int? _intOrNull(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

DateTime _date(dynamic v) {
  final parsed = _dateOrNull(v);
  return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// 解析 Unix 秒或 ISO 字符串；`0` / 空视为未设置。
DateTime? _dateOrNull(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty || s == '0') return null;
    final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized)?.toLocal();
  }
  if (v is int) {
    if (v == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true).toLocal();
  }
  if (v is num) {
    final sec = v.toInt();
    if (sec == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true).toLocal();
  }
  return null;
}

List<UcgPost> parsePostList(dynamic raw, {bool publicFeedOnly = false}) {
  if (raw is! List) return const [];
  final out = <UcgPost>[];
  for (final e in raw) {
    if (e is! Map<String, dynamic>) continue;
    final post = UcgPost.fromJson(e);
    if (publicFeedOnly && !post.isVisibleInPublicFeed) continue;
    out.add(post);
  }
  return out;
}

UcgPagedPosts parsePagedPosts(Map<String, dynamic>? data, {bool publicFeedOnly = false}) {
  if (data == null) {
    return const UcgPagedPosts(items: [], page: 1, pageSize: kUcgPageSize, total: 0);
  }
  final listRaw = data['list'] ?? data['items'] ?? data['records'];
  final page = _int(data['page']);
  final pageSize = _int(data['pageSize']);
  final total = _int(data['total']);
  return UcgPagedPosts(
    items: parsePostList(listRaw, publicFeedOnly: publicFeedOnly),
    page: page > 0 ? page : 1,
    pageSize: pageSize > 0 ? pageSize : kUcgPageSize,
    total: total,
  );
}
