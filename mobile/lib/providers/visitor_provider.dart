import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visitor_model.dart';
import '../services/visitor_service.dart';

class VisitorListState {
  final List<VisitorModel> visitors;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? pagination;

  const VisitorListState({
    this.visitors = const [],
    this.isLoading = false,
    this.error,
    this.pagination,
  });

  VisitorListState copyWith({
    List<VisitorModel>? visitors,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? pagination,
  }) {
    return VisitorListState(
      visitors: visitors ?? this.visitors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
    );
  }
}

class VisitorNotifier extends StateNotifier<VisitorListState> {
  final VisitorService _service = VisitorService();

  VisitorNotifier() : super(const VisitorListState());

  Future<void> loadVisitors({String? status, String? companyId, String? date}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getVisitors(
        status: status,
        companyId: companyId,
        date: date,
      );
      state = state.copyWith(
        isLoading: false,
        visitors: result['visitors'] as List<VisitorModel>,
        pagination: result['pagination'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void updateVisitor(VisitorModel updated) {
    state = state.copyWith(
      visitors: state.visitors.map((v) => v.id == updated.id ? updated : v).toList(),
    );
  }
}

final visitorProvider = StateNotifierProvider<VisitorNotifier, VisitorListState>(
  (ref) => VisitorNotifier(),
);

// For host — pending approval requests
final pendingVisitorProvider = StateNotifierProvider<VisitorNotifier, VisitorListState>(
  (ref) => VisitorNotifier(),
);
