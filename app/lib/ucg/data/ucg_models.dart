import 'ucg_media_url.dart';

const kUcgPageSize = 20;

enum UcgPostStatus {
  draft,
  pendingAudit,
  published,
  rejected;

  static UcgPostStatus fromApi(String? raw) {
    return switch (raw) {
      'draft' => UcgPostStatus.draft,
      'pending_audit' => UcgPostStatus.pendingAudit,
      'published' => UcgPostStatus.published,
      'rejected' => UcgPostStatus.rejected,
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
    this.bio = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
  });

  final String userId;
  final String nickname;
  final String? avatarKey;
  final String bio;
  final int followerCount;
  final int followingCount;
  final int postCount;

  String? get avatarUrl =>
      avatarKey == null || avatarKey!.isEmpty ? null : UcgMediaUrl.objectKeyToCdn(avatarKey!);

  factory UcgProfile.fromJson(Map<String, dynamic> json) {
    return UcgProfile(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarKey: json['avatarKey'] as String? ?? json['avatar'] as String?,
      bio: json['bio'] as String? ?? '',
      followerCount: _int(json['followerCount']),
      followingCount: _int(json['followingCount']),
      postCount: _int(json['postCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        if (avatarKey != null) 'avatarKey': avatarKey,
        'bio': bio,
      };
}

class UcgPost {
  const UcgPost({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    this.authorAvatarKey,
    required this.text,
    this.imageKeys = const [],
    this.videoKey,
    required this.status,
    this.rejectReason,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String authorId;
  final String authorNickname;
  final String? authorAvatarKey;
  final String text;
  final List<String> imageKeys;
  final String? videoKey;
  final UcgPostStatus status;
  final String? rejectReason;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  bool get isVideo => videoKey != null && videoKey!.isNotEmpty;

  String? get authorAvatarUrl => authorAvatarKey == null || authorAvatarKey!.isEmpty
      ? null
      : UcgMediaUrl.objectKeyToCdn(authorAvatarKey!);

  List<String> get imageUrls =>
      imageKeys.map(UcgMediaUrl.objectKeyToCdn).where((u) => u.isNotEmpty).toList();

  String? get videoUrl =>
      videoKey == null || videoKey!.isEmpty ? null : UcgMediaUrl.objectKeyToCdn(videoKey!);

  bool get isVisibleInPublicFeed => status == UcgPostStatus.published;

  UcgPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return UcgPost(
      id: id,
      authorId: authorId,
      authorNickname: authorNickname,
      authorAvatarKey: authorAvatarKey,
      text: text,
      imageKeys: imageKeys,
      videoKey: videoKey,
      status: status,
      rejectReason: rejectReason,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory UcgPost.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['imageKeys'] ?? json['images'];
    final keys = <String>[];
    if (imagesRaw is List) {
      for (final e in imagesRaw) {
        if (e is String && e.isNotEmpty) keys.add(e);
      }
    }
    return UcgPost(
      id: json['id'] as String? ?? json['postId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? json['userId'] as String? ?? '',
      authorNickname: json['authorNickname'] as String? ?? json['nickname'] as String? ?? '',
      authorAvatarKey: json['authorAvatarKey'] as String? ?? json['avatarKey'] as String?,
      text: json['text'] as String? ?? json['content'] as String? ?? '',
      imageKeys: keys,
      videoKey: json['videoKey'] as String?,
      status: UcgPostStatus.fromApi(json['status'] as String?),
      rejectReason: json['rejectReason'] as String? ?? json['reason'] as String?,
      createdAt: _date(json['createdAt']),
      likeCount: _int(json['likeCount']),
      commentCount: _int(json['commentCount']),
      likedByMe: json['likedByMe'] == true || json['liked'] == true,
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

  factory UcgComment.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final authorId = json['authorId'] as String? ?? json['userId'] as String? ?? '';
    return UcgComment(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      authorId: authorId,
      authorNickname: json['authorNickname'] as String? ?? json['nickname'] as String? ?? '',
      text: json['text'] as String? ?? json['content'] as String? ?? '',
      createdAt: _date(json['createdAt']),
      isMine: currentUserId != null && authorId == currentUserId,
    );
  }
}

class UcgConversation {
  const UcgConversation({
    required this.id,
    required this.peerId,
    required this.peerNickname,
    this.peerAvatarKey,
    this.lastMessagePreview = '',
    this.lastMessageAt,
    this.unreadCount = 0,
    this.pinned = false,
  });

  final String id;
  final String peerId;
  final String peerNickname;
  final String? peerAvatarKey;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool pinned;

  String? get peerAvatarUrl => peerAvatarKey == null || peerAvatarKey!.isEmpty
      ? null
      : UcgMediaUrl.objectKeyToCdn(peerAvatarKey!);

  UcgConversation copyWith({int? unreadCount, bool? pinned}) {
    return UcgConversation(
      id: id,
      peerId: peerId,
      peerNickname: peerNickname,
      peerAvatarKey: peerAvatarKey,
      lastMessagePreview: lastMessagePreview,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      pinned: pinned ?? this.pinned,
    );
  }

  factory UcgConversation.fromJson(Map<String, dynamic> json) {
    return UcgConversation(
      id: json['id'] as String? ?? json['conversationId'] as String? ?? '',
      peerId: json['peerId'] as String? ?? json['targetUserId'] as String? ?? '',
      peerNickname: json['peerNickname'] as String? ?? json['nickname'] as String? ?? '',
      peerAvatarKey: json['peerAvatarKey'] as String? ?? json['avatarKey'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? json['preview'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null ? _date(json['lastMessageAt']) : null,
      unreadCount: _int(json['unreadCount']),
      pinned: json['pinned'] == true,
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
    this.imageKey,
    this.videoKey,
    required this.createdAt,
    this.status = UcgChatMessageStatus.delivered,
    this.isMine = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? imageKey;
  final String? videoKey;
  final DateTime createdAt;
  final UcgChatMessageStatus status;
  final bool isMine;

  factory UcgChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['senderId'] as String? ?? json['fromUserId'] as String? ?? '';
    return UcgChatMessage(
      id: json['id'] as String? ?? json['messageId'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: senderId,
      text: json['text'] as String? ?? json['content'] as String? ?? '',
      imageKey: json['imageKey'] as String?,
      videoKey: json['videoKey'] as String?,
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

DateTime _date(dynamic v) {
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.fromMillisecondsSinceEpoch(0);
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
