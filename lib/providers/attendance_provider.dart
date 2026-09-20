import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = false;
  String? _error;
  String? _savedRollno;
  String? _savedPassword;

  List<AttendanceModel> get attendanceList => _attendanceList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get savedRollno => _savedRollno;
  String? get savedPassword => _savedPassword;

  AttendanceProvider() {
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    _savedRollno = prefs.getString('erpRollNo');
    _savedPassword = prefs.getString('erpPassword');
    
    final cachedData = prefs.getString('erpAttendanceData');
    if (cachedData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedData);
        _attendanceList = decoded.map((e) => AttendanceModel.fromJson(e)).toList();
        notifyListeners();
      } catch (e) {
        // Cache is corrupted or outdated
      }
    }
    
    // Auto-fetch if we have credentials and no cached data
    if (_savedRollno != null && _savedPassword != null && _attendanceList.isEmpty) {
      fetchAttendance(_savedRollno!, _savedPassword!, showLoading: false);
    }
  }

  Future<void> fetchAttendance(String rollno, String password, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await AttendanceService.getAttendance(rollno, password);
      _attendanceList = data;
      
      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('erpRollNo', rollno);
      await prefs.setString('erpPassword', password);
      
      // Convert list back to json string
      final jsonList = data.map((e) => e.toJson()).toList();
      await prefs.setString('erpAttendanceData', jsonEncode(jsonList));
      
      _savedRollno = rollno;
      _savedPassword = password;
      
    } catch (e) {
      if (showLoading) {
        _error = "Connection Failed. You're offline or server error. (${e.toString()})";
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> clearAttendance() async {
    _attendanceList = [];
    _error = null;
    _savedRollno = null;
    _savedPassword = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('erpRollNo');
    await prefs.remove('erpPassword');
    await prefs.remove('erpAttendanceData');
    
    notifyListeners();
  }
}
