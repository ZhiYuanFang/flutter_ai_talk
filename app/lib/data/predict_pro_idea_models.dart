import '../api/gateway_json.dart';

/// App 公开想法列表项（对齐 Go `predict-pro-ideas/list`）。
class PredictProIdeaItem {
  const PredictProIdeaItem({
    required this.id,
    required this.text,
    required this.babyName,
    required this.likeCount,
    required this.likedByMe,
    required this.isMine,
  });

  final int id;
  final String text;
  final String babyName;
  final int likeCount;
  final bool likedByMe;
  final bool isMine;

  /// 列表作者行：「{宝宝名}的家长」。
  String get authorLabel {
    final n = babyName.trim();
    if (n.isEmpty) return '宝宝的家长';
    return '$n的家长';
  }

  PredictProIdeaItem copyWith({
    int? id,
    String? text,
    String? babyName,
    int? likeCount,
    bool? likedByMe,
    bool? isMine,
  }) {
    return PredictProIdeaItem(
      id: id ?? this.id,
      text: text ?? this.text,
      babyName: babyName ?? this.babyName,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      isMine: isMine ?? this.isMine,
    );
  }

  factory PredictProIdeaItem.fromJson(Map<String, dynamic> json) {
    return PredictProIdeaItem(
      id: _readInt(json['id']) ?? 0,
      text: readGatewayStr(json, 'text', 'text') ?? '',
      babyName: readGatewayStr(json, 'babyName', 'baby_name') ?? '',
      likeCount: _readInt(json['likeCount']) ??
          _readInt(json['like_count']) ??
          0,
      likedByMe: _readBool(json['likedByMe']) ??
          _readBool(json['liked_by_me']) ??
          false,
      isMine: _readBool(json['isMine']) ??
          _readBool(json['is_mine']) ??
          false,
    );
  }

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static bool? _readBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }
}

/// like/unlike 响应。
class PredictProIdeaLikeResult {
  const PredictProIdeaLikeResult({
    required this.likeCount,
    required this.likedByMe,
  });

  final int likeCount;
  final bool likedByMe;

  factory PredictProIdeaLikeResult.fromJson(Map<String, dynamic> json) {
    return PredictProIdeaLikeResult(
      likeCount: PredictProIdeaItem._readInt(json['likeCount']) ??
          PredictProIdeaItem._readInt(json['like_count']) ??
          0,
      likedByMe: PredictProIdeaItem._readBool(json['likedByMe']) ??
          PredictProIdeaItem._readBool(json['liked_by_me']) ??
          false,
    );
  }
}
