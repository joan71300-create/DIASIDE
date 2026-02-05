import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coach_models.dart';
import '../services/coach_service.dart';

class CoachState {
  final bool isLoading;
  final CoachResponse? data;
  final String? error;
  final List<ChatMessage> history;

  CoachState({
    this.isLoading = false, 
    this.data, 
    this.error, 
    this.history = const []
  });

  CoachState copyWith({
    bool? isLoading, 
    CoachResponse? data, 
    String? error, 
    List<ChatMessage>? history
  }) {
    return CoachState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error, // Clears error if not provided (existing behavior)
      history: history ?? this.history,
    );
  }
}

class CoachNotifier extends StateNotifier<CoachState> {
  final CoachService _service;

  CoachNotifier(this._service) : super(CoachState());

  Future<void> getAdvice(UserHealthSnapshot snapshot) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getAdvice(snapshot: snapshot, history: state.history);
      
      // Add response to history
      var newHistory = List<ChatMessage>.from(state.history);
      if (result != null && result.advice.isNotEmpty) {
        newHistory.add(ChatMessage(role: "model", content: result.advice));
      }

      state = state.copyWith(isLoading: false, data: result, history: newHistory);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String message, UserHealthSnapshot snapshot, {String? imageBase64}) async {
    // Optimistic update
    var newHistory = List<ChatMessage>.from(state.history);
    
    // Si image, on peut ajouter un indicateur visuel dans le message user (ex: "[Image]")
    String displayContent = message;
    if (imageBase64 != null) {
      displayContent = "📸 [Image envoyée] $message";
    }
    newHistory.add(ChatMessage(role: "user", content: displayContent));
    
    state = state.copyWith(isLoading: true, error: null, history: newHistory);

    try {
      final result = await _service.getAdvice(
        snapshot: snapshot, 
        history: newHistory, 
        userMessage: message,
        imageBase64: imageBase64
      );
      
      if (result != null && result.advice.isNotEmpty) {
        newHistory.add(ChatMessage(role: "model", content: result.advice));
      }
      
      state = state.copyWith(isLoading: false, data: result, history: newHistory);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  return CoachNotifier(coachService);
});
