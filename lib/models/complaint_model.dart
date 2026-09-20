import 'user_model.dart';

class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final UserModel? student;
  final String? studentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.student,
    this.studentId,
    this.createdAt,
    this.updatedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      student: json['studentId'] != null && json['studentId'] is Map<String, dynamic>
          ? UserModel.fromJson(json['studentId'])
          : null,
      studentId: json['studentId'] is String ? json['studentId'] : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'studentId': student?.id ?? studentId,
    };
  }
}
