import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await ApiService.post('/auth/login', body: {
      'identifier': identifier,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data);
      final token = data['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(data));
      
      return {'user': user, 'token': token};
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  static Future<void> register(Map<String, dynamic> userData) async {
    final response = await ApiService.post('/auth/register', body: userData);
    if (response.statusCode != 201 && response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userStr = prefs.getString('user');
    
    if (token != null && userStr != null) {
      final userJson = jsonDecode(userStr);
      return {
        'user': UserModel.fromJson(userJson),
        'token': token,
      };
    }
    return null;
  }
}
