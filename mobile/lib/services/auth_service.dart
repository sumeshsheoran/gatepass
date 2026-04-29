import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_client.dart';

String _err(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'] as String;
    return e.message ?? 'Request failed';
  }
  return e.toString().replaceFirst('Exception: ', '');
}

class AuthService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data;
      if (data['success'] == true) {
        await ApiClient().setToken(data['token']);
        return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
      }
      throw Exception(data['message'] ?? 'Login failed');
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<void> logout() async {
    await ApiClient().clearToken();
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.patch('/auth/fcm-token', data: {'fcmToken': fcmToken});
    } catch (_) {}
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    List<String>? companyIds,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        'companyIds': companyIds ?? [],
      });
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['user']);
      }
      throw Exception(response.data['message'] ?? 'Registration failed');
    } catch (e) {
      throw Exception(_err(e));
    }
  }
}
