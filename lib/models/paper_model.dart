class PaperModel {
  final String id;
  final String name;
  final String code;
  final String course;
  final String semester;
  final String year;
  final String pdfUrl;
  final String size;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaperModel({
    required this.id,
    required this.name,
    required this.code,
    required this.course,
    required this.semester,
    required this.year,
    required this.pdfUrl,
    required this.size,
    this.createdAt,
    this.updatedAt,
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) {
    return PaperModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      course: json['course'] ?? '',
      semester: json['semester'] ?? '',
      year: json['year'] ?? '',
      pdfUrl: json['pdfUrl'] ?? '',
      size: json['size'] ?? 'Unknown Size',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'course': course,
      'semester': semester,
      'year': year,
      'pdfUrl': pdfUrl,
      'size': size,
    };
  }
}
