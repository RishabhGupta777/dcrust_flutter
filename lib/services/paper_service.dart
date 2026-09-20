import 'dart:convert';
import '../models/paper_model.dart';
import 'api_service.dart';

class PaperService {
  static Future<List<PaperModel>> getPapers({
    String course = '',
    String semester = '',
    String search = '',
    String type = '',
  }) async {
    try {
      final queryParams = <String>[];
      if (course.isNotEmpty) queryParams.add('course=$course');
      if (semester.isNotEmpty) queryParams.add('semester=$semester');
      if (search.isNotEmpty) queryParams.add('search=$search');
      if (type.isNotEmpty) queryParams.add('type=$type');

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      
      final response = await ApiService.get('/papers$queryString');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> papersJson = json['papers'] ?? [];
        return papersJson.map((e) => PaperModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load papers');
      }
    } catch (e) {
      throw Exception('Error fetching papers: $e');
    }
  }
}
