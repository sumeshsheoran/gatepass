import 'package:equatable/equatable.dart';

class CompanyModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final bool isActive;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.isActive = true,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      email: json['email'],
      logoUrl: json['logoUrl'],
      isActive: json['isActive'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
