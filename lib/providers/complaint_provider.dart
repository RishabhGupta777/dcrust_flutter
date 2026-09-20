import 'package:flutter/foundation.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';

class ComplaintProvider with ChangeNotifier {
  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  String? _error;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchComplaints() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _complaints = await ComplaintService.getComplaints();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createComplaint(String title, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newComplaint = await ComplaintService.createComplaint(title, description);
      _complaints.insert(0, newComplaint);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
