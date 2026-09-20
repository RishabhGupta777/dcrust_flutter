import 'dart:convert';
import '../models/chat_model.dart';
import 'api_service.dart';

class ChatService {
  static Future<List<ChatRoomModel>> getRooms() async {
    try {
      final response = await ApiService.get('/chat/rooms');
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => ChatRoomModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load chat rooms');
      }
    } catch (e) {
      throw Exception('Error fetching chat rooms: $e');
    }
  }

  static Future<List<ChatMessageModel>> getMessages(String roomId) async {
    try {
      final response = await ApiService.get('/chat/messages/$roomId');
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => ChatMessageModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }
}
