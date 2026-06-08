import '../api/gateway_json.dart';

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.question,
    required this.status,
    required this.createdAt,
    this.officialReply,
    this.repliedAt,
  });

  final int id;
  final String question;
  final String? officialReply;
  final int status;
  final int createdAt;
  final int? repliedAt;

  bool get isReplied => status == 1 || (officialReply != null && officialReply!.trim().isNotEmpty);

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: _readInt(json['id']) ?? 0,
      question: readGatewayStr(json, 'question', 'question') ?? '',
      officialReply: readGatewayStr(json, 'officialReply', 'official_reply'),
      status: _readInt(json['status']) ?? 0,
      createdAt: _readInt(json['createdAt']) ?? _readInt(json['created_at']) ?? 0,
      repliedAt: _readInt(json['repliedAt']) ?? _readInt(json['replied_at']),
    );
  }

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
