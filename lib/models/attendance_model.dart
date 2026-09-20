class AttendanceDetail {
  final String date;
  final String time;
  final bool status;

  AttendanceDetail({
    required this.date,
    required this.time,
    required this.status,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'time': time,
      'status': status,
    };
  }
}

class AttendanceModel {
  final String code;
  final String name;
  final String attendance;
  final List<AttendanceDetail> details;

  AttendanceModel({
    required this.code,
    required this.name,
    required this.attendance,
    required this.details,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      attendance: json['attendance']?.toString() ?? '0',
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => AttendanceDetail.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'attendance': attendance,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}
