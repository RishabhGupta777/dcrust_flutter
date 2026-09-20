import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Production URL
  static const String _productionBaseUrl = 'https://dcrust-server.vercel.app/api';
  
  // Local Development URLs
  static const String _localBaseUrl = 'http://localhost:5000/api';
  static const String _emulatorBaseUrl = 'http://10.0.2.2:5000/api';

  // Toggle this to switch between local and production
  static const bool _useLocalBackend = false;

  static String get baseUrl {
    if (!_useLocalBackend) {
      return _productionBaseUrl;
    }
    
    if (kIsWeb) {
      return _localBaseUrl;
    } else if (Platform.isAndroid) {
      return _emulatorBaseUrl;
    } else {
      return _localBaseUrl;
    }
  }

  static String getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('data:')) return path;
    
    // Determine the base domain without /api
    String domain = baseUrl.replaceAll(RegExp(r'/api$'), '');
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$domain$path';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
}
