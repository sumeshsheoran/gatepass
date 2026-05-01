import 'package:dio/dio.dart';
import '../models/company_model.dart';
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

class CompanyService {
  final _dio = ApiClient().dio;

  Future<List<CompanyModel>> getCompanies() async {
    try {
      final response = await _dio.get('/companies');
      return (response.data['companies'] as List)
          .map((c) => CompanyModel.fromJson(c))
          .toList();
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<CompanyModel> createCompany({
    required String name,
    required String address,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _dio.post('/companies', data: {
        'name': name,
        'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      });
      return CompanyModel.fromJson(response.data['company']);
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<CompanyModel> updateCompany(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/companies/$id', data: data);
      return CompanyModel.fromJson(response.data['company']);
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<void> assignGuard(String companyId, String guardId) async {
    try {
      await _dio.post('/companies/$companyId/assign-guard', data: {'guardId': guardId});
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<void> removeGuard(String companyId, String guardId) async {
    try {
      await _dio.delete('/companies/$companyId/remove-guard/$guardId');
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<List<UserModel>> searchHosts(String companyId, {String? q}) async {
    try {
      final response = await _dio.get('/users/hosts/search', queryParameters: {
        'companyId': companyId,
        if (q != null && q.isNotEmpty) 'q': q,
      });
      return (response.data['hosts'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<List<UserModel>> getUsers({String? role, String? companyId}) async {
    try {
      final response = await _dio.get('/users', queryParameters: {
        if (role != null) 'role': role,
        if (companyId != null) 'companyId': companyId,
      });
      return (response.data['users'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/users', data: data);
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/users/$id', data: data);
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/users/$id');
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<Map<String, dynamic>> getDashboardLive({String? companyId}) async {
    try {
      final response = await _dio.get('/dashboard/live', queryParameters: {
        if (companyId != null) 'companyId': companyId,
      });
      return response.data['data'];
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<Map<String, dynamic>> getDashboardStats({String? companyId}) async {
    try {
      final response = await _dio.get('/dashboard/stats', queryParameters: {
        if (companyId != null) 'companyId': companyId,
      });
      return response.data['stats'];
    } catch (e) {
      throw Exception(_err(e));
    }
  }
}
