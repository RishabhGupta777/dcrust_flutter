import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = true;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    // Only notify if we weren't already loading
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final storedData = await AuthService.getStoredUser();
      if (storedData != null) {
        _user = storedData['user'];
        _token = storedData['token'];
      }
    } catch (e) {
      _user = null;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await AuthService.login(identifier, password);
      _user = data['user'];
      _token = data['token'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }
}
