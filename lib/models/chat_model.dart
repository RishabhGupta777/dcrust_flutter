import 'user_model.dart';

class ChatMessageModel {
  final String id;
  final String chatRoomId;
  final UserModel? sender;
  final String? senderId;
  final String content;
  final String status;
  final bool isDeletedForEveryone;
  final bool isEdited;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    this.sender,
    this.senderId,
    required this.content,
    required this.status,
    required this.isDeletedForEveryone,
    required this.isEdited,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['_id'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      sender: json['senderId'] != null && json['senderId'] is Map<String, dynamic>
          ? UserModel.fromJson(json['senderId'])
          : null,
      senderId: json['senderId'] is String ? json['senderId'] : null,
      content: json['content'] ?? '',
      status: json['status'] ?? 'sent',
      isDeletedForEveryone: json['isDeletedForEveryone'] ?? false,
      isEdited: json['isEdited'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatRoomId': chatRoomId,
      'senderId': sender?.id ?? senderId,
      'content': content,
      'status': status,
      'isDeletedForEveryone': isDeletedForEveryone,
      'isEdited': isEdited,
    };
  }
}

class ChatRoomModel {
  final String id;
  final List<UserModel> participants;
  final ChatMessageModel? lastMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => UserModel.fromJson(e))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null && json['lastMessage'] is Map<String, dynamic>
          ? ChatMessageModel.fromJson(json['lastMessage'])
          : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
