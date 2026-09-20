class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String linkedInProfile;
  final String role;
  final bool isVerified;
  final bool isApprovedByAdmin;
  final bool isOnline;
  final DateTime? lastSeen;
  final List<String> skills;
  final Map<String, dynamic>? educationDetails;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.linkedInProfile,
    required this.role,
    required this.isVerified,
    required this.isApprovedByAdmin,
    required this.isOnline,
    this.lastSeen,
    required this.skills,
    this.educationDetails,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      linkedInProfile: json['linkedInProfile'] ?? '',
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
      isApprovedByAdmin: json['isApprovedByAdmin'] ?? false,
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen']) : null,
      skills: List<String>.from(json['skills'] ?? []),
      educationDetails: json['educationDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'linkedInProfile': linkedInProfile,
      'role': role,
      'isVerified': isVerified,
      'isApprovedByAdmin': isApprovedByAdmin,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'skills': skills,
      'educationDetails': educationDetails,
    };
  }
}
