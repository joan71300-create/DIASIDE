import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/coach_models.dart';

/// Provider pour persister l'historique des conversations Coach
class CoachHistoryNotifier extends StateNotifier<List<ChatMessage>> {
  CoachHistoryNotifier() : super([]) {
    _loadHistory();
  }

  final _storage = const FlutterSecureStorage();
  static const String _historyKey = 'coach_chat_history';

  Future<void> _loadHistory() async {
    try {
      final historyJson = await _storage.read(key: _historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        state = decoded.map((e) => ChatMessage.fromJson(e)).toList();
      }
    } catch (e) {
      print("Erreur chargement historique coach: $e");
    }
  }

  Future<void> saveHistory(List<ChatMessage> history) async {
    try {
      final historyJson = jsonEncode(history.map((e) => e.toJson()).toList());
      await _storage.write(key: _historyKey, value: historyJson);
      state = history;
    } catch (e) {
      print("Erreur sauvegarde historique coach: $e");
    }
  }

  Future<void> clearHistory() async {
    await _storage.delete(key: _historyKey);
    state = [];
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
    saveHistory(state);
  }

  void addUserMessage(String content) {
    addMessage(ChatMessage(role: "user", content: content));
  }

  void addAssistantMessage(String content) {
    addMessage(ChatMessage(role: "model", content: content));
  }
}

final coachHistoryProvider = StateNotifierProvider<CoachHistoryNotifier, List<ChatMessage>>((ref) {
  return CoachHistoryNotifier();
});
