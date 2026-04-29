import 'dart:io';
import 'package:dio/dio.dart';
import '../models/visitor_model.dart';
import 'api_client.dart';

class VisitorService {
  final _dio = ApiClient().dio;

  Future<VisitorModel> createVisitor({
    required String companyId,
    required String hostId,
    required String visitorName,
    required String visitorPhone,
    String? visitorEmail,
    required String purpose,
    File? visitorPhoto,
    File? idProof,
  }) async {
    final formData = FormData.fromMap({
      'companyId': companyId,
      'hostId': hostId,
      'visitorName': visitorName,
      'visitorPhone': visitorPhone,
      if (visitorEmail != null) 'visitorEmail': visitorEmail,
      'purpose': purpose,
      if (visitorPhoto != null)
        'visitorPhoto': await MultipartFile.fromFile(visitorPhoto.path, filename: 'visitor_photo.jpg'),
      if (idProof != null)
        'idProof': await MultipartFile.fromFile(idProof.path, filename: 'id_proof.jpg'),
    });

    final response = await _dio.post('/visitors', data: formData);
    if (response.data['success'] == true) {
      return VisitorModel.fromJson(response.data['visitor']);
    }
    throw Exception(response.data['message'] ?? 'Failed to create visitor entry');
  }

  Future<Map<String, dynamic>> getVisitors({
    String? status,
    String? companyId,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/visitors', queryParameters: {
      if (status != null) 'status': status,
      if (companyId != null) 'companyId': companyId,
      if (date != null) 'date': date,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return {
      'visitors': (data['visitors'] as List).map((v) => VisitorModel.fromJson(v)).toList(),
      'pagination': data['pagination'],
    };
  }

  Future<VisitorModel> getVisitor(String id) async {
    final response = await _dio.get('/visitors/$id');
    return VisitorModel.fromJson(response.data['visitor']);
  }

  Future<VisitorModel> approveVisitor(String id) async {
    final response = await _dio.patch('/visitors/$id/approve');
    return VisitorModel.fromJson(response.data['visitor']);
  }

  Future<VisitorModel> denyVisitor(String id, {String? reason}) async {
    final response = await _dio.patch('/visitors/$id/deny', data: {
      if (reason != null) 'reason': reason,
    });
    return VisitorModel.fromJson(response.data['visitor']);
  }

  Future<VisitorModel> checkoutVisitor(String id) async {
    final response = await _dio.patch('/visitors/$id/checkout');
    return VisitorModel.fromJson(response.data['visitor']);
  }
}
