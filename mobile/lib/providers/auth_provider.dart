import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service = AuthService();

  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await _service.getMe();
    state = AuthState(user: user);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.login(email, password);
      state = AuthState(user: result['user'] as UserModel);
      _uploadFcmToken(); // fire-and-forget
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> _uploadFcmToken() async {
    try {
      // Try up to 3 times — FCM token can be null briefly after app start
      String? token;
      for (int i = 0; i < 3; i++) {
        token = await NotificationService().getToken();
        if (token != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }
      if (token != null) {
        await _service.updateFcmToken(token);
      }
      // Keep token fresh if FCM rotates it
      NotificationService().onTokenRefresh.listen((t) => _service.updateFcmToken(t));
    } catch (_) {}
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
