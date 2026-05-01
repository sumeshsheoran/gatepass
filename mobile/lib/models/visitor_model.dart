import 'package:equatable/equatable.dart';

class VisitorModel extends Equatable {
  final String id;
  final String companyId;
  final String guardId;
  final String guardName;
  final String hostId;
  final String hostName;
  final String hostPhone;
  final String visitorName;
  final String visitorPhone;
  final String? visitorEmail;
  final String? visitorCompany;
  final String? visitorPhoto;
  final String? idProofPhoto;
  final String purpose;
  final String status;
  final String checkInTime;
  final String? checkOutTime;
  final String? approvedAt;
  final String? deniedAt;
  final String? denialReason;

  const VisitorModel({
    required this.id,
    required this.companyId,
    required this.guardId,
    required this.guardName,
    required this.hostId,
    required this.hostName,
    required this.hostPhone,
    required this.visitorName,
    required this.visitorPhone,
    this.visitorEmail,
    this.visitorCompany,
    this.visitorPhoto,
    this.idProofPhoto,
    required this.purpose,
    required this.status,
    required this.checkInTime,
    this.checkOutTime,
    this.approvedAt,
    this.deniedAt,
    this.denialReason,
  });

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: json['id'] ?? json['_id'] ?? '',
      companyId: json['companyId'] ?? '',
      guardId: json['guardId'] ?? '',
      guardName: json['guardName'] ?? '',
      hostId: json['hostId'] ?? '',
      hostName: json['hostName'] ?? '',
      hostPhone: json['hostPhone'] ?? '',
      visitorName: json['visitorName'] ?? '',
      visitorPhone: json['visitorPhone'] ?? '',
      visitorEmail: json['visitorEmail'],
      visitorCompany: json['visitorCompany'],
      visitorPhoto: json['visitorPhoto'],
      idProofPhoto: json['idProofPhoto'],
      purpose: json['purpose'] ?? '',
      status: json['status'] ?? 'pending',
      checkInTime: json['checkInTime'] ?? '',
      checkOutTime: json['checkOutTime'],
      approvedAt: json['approvedAt'],
      deniedAt: json['deniedAt'],
      denialReason: json['denialReason'],
    );
  }

  @override
  List<Object?> get props => [id, status];
}
