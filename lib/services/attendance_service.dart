import 'dart:convert';
import '../models/attendance_model.dart';
import 'api_service.dart';

class AttendanceService {
  static Future<List<AttendanceModel>> getAttendance(String rollno, String password) async {
    try {
      final response = await ApiService.post('/attendance', body: {
        'rollno': rollno,
        'password': password,
      });

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => AttendanceModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch attendance');
      }
    } catch (e) {
      throw Exception('Error fetching attendance: $e');
    }
  }
}
