import '../models/company_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class CompanyService {
  final _dio = ApiClient().dio;

  Future<List<CompanyModel>> getCompanies() async {
    final response = await _dio.get('/companies');
    return (response.data['companies'] as List)
        .map((c) => CompanyModel.fromJson(c))
        .toList();
  }

  Future<CompanyModel> createCompany({
    required String name,
    required String address,
    String? phone,
    String? email,
  }) async {
    final response = await _dio.post('/companies', data: {
      'name': name,
      'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    });
    return CompanyModel.fromJson(response.data['company']);
  }

  Future<CompanyModel> updateCompany(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/companies/$id', data: data);
    return CompanyModel.fromJson(response.data['company']);
  }

  Future<void> assignGuard(String companyId, String guardId) async {
    await _dio.post('/companies/$companyId/assign-guard', data: {'guardId': guardId});
  }

  Future<void> removeGuard(String companyId, String guardId) async {
    await _dio.delete('/companies/$companyId/remove-guard/$guardId');
  }

  Future<List<UserModel>> searchHosts(String companyId, {String? q}) async {
    final response = await _dio.get('/users/hosts/search', queryParameters: {
      'companyId': companyId,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (response.data['hosts'] as List)
        .map((u) => UserModel.fromJson(u))
        .toList();
  }

  Future<List<UserModel>> getUsers({String? role, String? companyId}) async {
    final response = await _dio.get('/users', queryParameters: {
      if (role != null) 'role': role,
      if (companyId != null) 'companyId': companyId,
    });
    return (response.data['users'] as List)
        .map((u) => UserModel.fromJson(u))
        .toList();
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final response = await _dio.post('/users', data: data);
    return UserModel.fromJson(response.data['user']);
  }

  Future<Map<String, dynamic>> getDashboardLive({String? companyId}) async {
    final response = await _dio.get('/dashboard/live', queryParameters: {
      if (companyId != null) 'companyId': companyId,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getDashboardStats({String? companyId}) async {
    final response = await _dio.get('/dashboard/stats', queryParameters: {
      if (companyId != null) 'companyId': companyId,
    });
    return response.data['stats'];
  }
}
