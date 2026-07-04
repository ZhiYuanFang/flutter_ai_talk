import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ucg_models.dart';

const _draftKey = 'ucg_compose_draft_v1';

class UcgComposeDraftStore {
  Future<UcgComposeDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return UcgComposeDraft.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  Future<void> save(UcgComposeDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final next = UcgComposeDraft(
      text: draft.text,
      imageKeys: draft.imageKeys,
      videoKey: draft.videoKey,
      editingPostId: draft.editingPostId,
      updatedAt: DateTime.now(),
      debateEnabled: draft.debateEnabled,
      debateLeft: draft.debateLeft,
      debateRight: draft.debateRight,
    );
    await prefs.setString(_draftKey, jsonEncode(next.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}
