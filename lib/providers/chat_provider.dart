import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  List<ChatRoomModel> _rooms = [];
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  String? _error;

  List<ChatRoomModel> get rooms => _rooms;
  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;

  Future<void> fetchRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rooms = await ChatService.getRooms();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String roomId) async {
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await ChatService.getMessages(roomId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }
  
  void addMessageLocally(ChatMessageModel message) {
    _messages.add(message);
    notifyListeners();
  }
}
