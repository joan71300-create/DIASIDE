import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coach_models.dart';
import '../services/coach_service.dart';

class CoachState {
  final bool isLoading;
  final CoachResponse? data;
  final String? error;

  CoachState({this.isLoading = false, this.data, this.error});

  CoachState copyWith({bool? isLoading, CoachResponse? data, String? error}) {
    return CoachState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class CoachNotifier extends StateNotifier<CoachState> {
  final CoachService _service;

  CoachNotifier(this._service) : super(CoachState());

  Future<void> getAdvice(UserHealthSnapshot snapshot) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getAdvice(snapshot);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  return CoachNotifier(coachService);
});
