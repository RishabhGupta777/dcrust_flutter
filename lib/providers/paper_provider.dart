import 'package:flutter/foundation.dart';
import '../models/paper_model.dart';
import '../services/paper_service.dart';

class PaperProvider with ChangeNotifier {
  List<PaperModel> _papers = [];
  bool _isLoading = false;
  String? _error;

  List<PaperModel> get papers => _papers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPapers({
    String course = '',
    String semester = '',
    String search = '',
    String type = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _papers = await PaperService.getPapers(
        course: course,
        semester: semester,
        search: search,
        type: type,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
