import 'dart:convert';
import '../models/complaint_model.dart';
import 'api_service.dart';

class ComplaintService {
  static Future<List<ComplaintModel>> getComplaints() async {
    try {
      final response = await ApiService.get('/complaints');
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => ComplaintModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load complaints');
      }
    } catch (e) {
      throw Exception('Error fetching complaints: $e');
    }
  }

  static Future<ComplaintModel> createComplaint(String title, String description) async {
    try {
      final response = await ApiService.post('/complaints', body: {
        'title': title,
        'description': description,
      });

      if (response.statusCode == 201) {
        return ComplaintModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create complaint');
      }
    } catch (e) {
      throw Exception('Error creating complaint: $e');
    }
  }
}
