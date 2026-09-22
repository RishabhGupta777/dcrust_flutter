import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../widgets/app_drawer.dart';

class ChatScreen extends StatefulWidget {
  final String? startChatWith;
  const ChatScreen({super.key, this.startChatWith});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  io.Socket? _socket;
  bool _socketConnected = false;

  List<ChatRoomModel> _rooms = [];
  bool _roomsLoaded = false;
  ChatRoomModel? _activeRoom;
  
  List<ChatMessageModel> _messages = [];
  bool _messagesLoading = false;
  
  String _sidebarSearchQuery = '';
  final TextEditingController _messageController = TextEditingController();
  
  List<UserModel> _directoryUsers = [];
  
  List<String> _selectedMessages = [];
  ChatMessageModel? _editingMessage;
  
  bool _showSidebarOnMobile = true;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      if (widget.startChatWith != null) {
        _showSidebarOnMobile = false;
      }
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    _fetchDirectory();
    await _fetchRooms();

    // Initialize Socket
    final socketUrl = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '');
    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('setup', user.toJson());
      setState(() => _socketConnected = true);
    });

    _setupSocketListeners();
    
    // Check if we need to start a new chat
    if (widget.startChatWith != null) {
      final targetUserId = widget.startChatWith!;
      final existingRoom = _rooms.cast<ChatRoomModel?>().firstWhere(
        (r) => r?.participants.any((p) => p.id == targetUserId) ?? false, 
        orElse: () => null
      );
      
      if (existingRoom != null) {
        _selectRoom(existingRoom);
      } else {
        _startNewChat(targetUserId);
      }
    }
  }
  
  void _setupSocketListeners() {
    if (_socket == null) return;
    final user = Provider.of<AuthProvider>(context, listen: false).user!;

    _socket!.on('receive_message', (data) {
      final newMessage = ChatMessageModel.fromJson(data);
      final isMyMessage = newMessage.senderId == user.id || newMessage.sender?.id == user.id;

      if (_activeRoom != null && _activeRoom!.id == newMessage.chatRoomId) {
        setState(() => _messages.add(newMessage));
      }

      if (!isMyMessage) {
        if (_activeRoom != null && _activeRoom!.id == newMessage.chatRoomId) {
          _socket!.emit('mark_room_messages_read', {'roomId': _activeRoom!.id, 'userId': user.id});
        } else {
          _socket!.emit('mark_message_status', {'messageId': newMessage.id, 'roomId': newMessage.chatRoomId, 'status': 'delivered'});
        }
      }
      
      _updateRoomLastMessage(newMessage.chatRoomId, newMessage);
    });

    _socket!.on('message_notification', (data) {
      final newMessage = ChatMessageModel.fromJson(data);
      _updateRoomLastMessage(newMessage.chatRoomId, newMessage);
    });

    _socket!.on('chat_created', (data) {
      final newRoom = ChatRoomModel.fromJson(data);
      if (!_rooms.any((r) => r.id == newRoom.id)) {
        setState(() => _rooms.insert(0, newRoom));
        _socket!.emit('join_room', newRoom.id);
      }
    });
    
    _socket!.on('message_edited', (data) {
       final updatedMessage = ChatMessageModel.fromJson(data);
       setState(() {
         final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
         if (index != -1) _messages[index] = updatedMessage;
       });
       _updateRoomLastMessage(updatedMessage.chatRoomId, updatedMessage);
    });
    
    _socket!.on('messages_deleted', (data) {
       final messageIds = List<String>.from(data['messageIds']);
       final type = data['type'];
       
       setState(() {
         if (type == 'for_everyone') {
           for (var i = 0; i < _messages.length; i++) {
             if (messageIds.contains(_messages[i].id)) {
               _messages[i] = ChatMessageModel(
                 id: _messages[i].id,
                 chatRoomId: _messages[i].chatRoomId,
                 content: _messages[i].content,
                 status: _messages[i].status,
                 isDeletedForEveryone: true,
                 isEdited: _messages[i].isEdited,
                 senderId: _messages[i].senderId,
                 sender: _messages[i].sender,
               );
             }
           }
         } else if (type == 'for_me') {
           _messages.removeWhere((m) => messageIds.contains(m.id));
         }
         _selectedMessages.clear();
       });
    });
  }
  
  void _updateRoomLastMessage(String roomId, ChatMessageModel message) {
    setState(() {
      final index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        final room = _rooms[index];
        _rooms[index] = ChatRoomModel(
          id: room.id,
          participants: room.participants,
          lastMessage: message,
          createdAt: room.createdAt,
          updatedAt: room.updatedAt,
        );
        _rooms.sort((a, b) {
          final aDate = a.lastMessage?.createdAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.lastMessage?.createdAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      }
    });
  }

  Future<void> _fetchRooms() async {
    try {
      final response = await ApiService.get('/chat/rooms');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _rooms = data.map((json) => ChatRoomModel.fromJson(json)).toList();
          _roomsLoaded = true;
        });
        for (var room in _rooms) {
          _socket?.emit('join_room', room.id);
        }
      }
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      setState(() => _roomsLoaded = true);
    }
  }

  Future<void> _fetchDirectory() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    try {
      final response = await ApiService.get('/auth/directory');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _directoryUsers = data.map((json) => UserModel.fromJson(json)).where((u) => u.id != user.id).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching directory: $e');
    }
  }

  Future<void> _fetchMessages(String roomId) async {
    setState(() => _messagesLoading = true);
    try {
      final response = await ApiService.get('/chat/messages/$roomId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages = data.map((json) => ChatMessageModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      setState(() => _messagesLoading = false);
    }
  }

  void _selectRoom(ChatRoomModel room) {
    setState(() {
      _activeRoom = room;
      _showSidebarOnMobile = false;
      _selectedMessages.clear();
      _editingMessage = null;
      _messageController.clear();
    });
    _fetchMessages(room.id);
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _socket?.emit('mark_room_messages_read', {'roomId': room.id, 'userId': user.id});
    }
  }

  Future<void> _startNewChat(String targetUserId) async {
    try {
      final response = await ApiService.post('/chat/rooms', body: {'userId': targetUserId});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newRoom = ChatRoomModel.fromJson(data);
        if (!_rooms.any((r) => r.id == newRoom.id)) {
          setState(() => _rooms.insert(0, newRoom));
          _socket?.emit('new_chat_created', {'room': data, 'participants': data['participants']});
          _socket?.emit('join_room', newRoom.id);
        }
        _selectRoom(newRoom);
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeRoom == null || _socket == null) return;
    final user = Provider.of<AuthProvider>(context, listen: false).user!;

    if (_editingMessage != null) {
      _socket!.emit('edit_message', {
        'messageId': _editingMessage!.id,
        'newContent': text,
        'roomId': _activeRoom!.id
      });
      setState(() => _editingMessage = null);
    } else {
      _socket!.emit('send_message', {
        'roomId': _activeRoom!.id,
        'senderId': user.id,
        'content': text,
      });
    }
    _messageController.clear();
  }
  
  UserModel? _getOtherParticipant(ChatRoomModel? room) {
    if (room == null || room.participants.isEmpty) return null;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return room.participants.firstWhere((p) => p.id != user?.id, orElse: () => room.participants.first);
  }
  
  void _toggleSelection(String msgId) {
    setState(() {
      if (_selectedMessages.contains(msgId)) {
        _selectedMessages.remove(msgId);
      } else {
        _selectedMessages.add(msgId);
      }
    });
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Please login to use chat')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;
        
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: isDesktop ? null : AppBar(
            backgroundColor: _selectedMessages.isNotEmpty ? Colors.indigo.shade600 : Colors.white,
            foregroundColor: _selectedMessages.isNotEmpty ? Colors.white : Colors.black87,
            title: _selectedMessages.isNotEmpty 
              ? Text('${_selectedMessages.length} selected') 
              : (_showSidebarOnMobile ? const Text('Chats') : Text(_getOtherParticipant(_activeRoom)?.name ?? '')),
            leading: !_showSidebarOnMobile && _selectedMessages.isEmpty
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _showSidebarOnMobile = true))
              : (_selectedMessages.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedMessages.clear())) 
                  : null),
            actions: _selectedMessages.isNotEmpty 
              ? [
                  IconButton(icon: const Icon(Icons.copy), onPressed: () {
                    final texts = _messages.where((m) => _selectedMessages.contains(m.id)).map((m) => m.content).join('\n');
                    Clipboard.setData(ClipboardData(text: texts));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                    setState(() => _selectedMessages.clear());
                  }),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () {
                    if (_socket != null && _activeRoom != null) {
                      _socket!.emit('delete_messages', {'messageIds': _selectedMessages, 'type': 'for_me', 'roomId': _activeRoom!.id, 'userId': user.id});
                    }
                  })
                ] 
              : null,
          ),
          drawer: _showSidebarOnMobile && isDesktop ? null : const AppDrawer(),
          body: Row(
            children: [
              // SIDEBAR
              if (isDesktop || _showSidebarOnMobile)
                Container(
                  width: isDesktop ? 350 : constraints.maxWidth,
                  color: Colors.white,
                  child: Column(
                    children: [
                      if (isDesktop)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: const Row(
                            children: [
                              Text('Chats', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search chats...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => setState(() => _sidebarSearchQuery = v.toLowerCase()),
                        ),
                      ),
                      Expanded(
                        child: !_roomsLoaded 
                          ? const Center(child: CircularProgressIndicator())
                          : _buildSidebarList(),
                      ),
                    ],
                  ),
                ),
                
              // MAIN CHAT AREA
              if (isDesktop || !_showSidebarOnMobile)
                Expanded(
                  child: _activeRoom == null
                    ? const Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Select a chat to start messaging', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ))
                    : Column(
                        children: [
                          if (isDesktop && _selectedMessages.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.indigo.shade100,
                                    foregroundColor: Colors.indigo.shade700,
                                    child: Text(_getOtherParticipant(_activeRoom)?.name[0] ?? '?'),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(_getOtherParticipant(_activeRoom)?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          if (isDesktop && _selectedMessages.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.indigo.shade600,
                              child: Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _selectedMessages.clear())),
                                  Text('${_selectedMessages.length} selected', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  IconButton(icon: const Icon(Icons.copy, color: Colors.white), onPressed: () {
                                    final texts = _messages.where((m) => _selectedMessages.contains(m.id)).map((m) => m.content).join('\n');
                                    Clipboard.setData(ClipboardData(text: texts));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                                    setState(() => _selectedMessages.clear());
                                  }),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: () {
                                    if (_socket != null && _activeRoom != null) {
                                      _socket!.emit('delete_messages', {'messageIds': _selectedMessages, 'type': 'for_me', 'roomId': _activeRoom!.id, 'userId': user.id});
                                    }
                                  }),
                                ],
                              ),
                            ),
                          Expanded(
                            child: _messagesLoading 
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final msg = _messages[index];
                                    final isMe = msg.senderId == user.id || msg.sender?.id == user.id;
                                    final isSelected = _selectedMessages.contains(msg.id);
                                    
                                    return GestureDetector(
                                      onLongPress: () => _toggleSelection(msg.id),
                                      onTap: () {
                                        if (_selectedMessages.isNotEmpty) _toggleSelection(msg.id);
                                      },
                                      child: Container(
                                        color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Align(
                                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: msg.isDeletedForEveryone 
                                                  ? Colors.grey.shade300 
                                                  : (isMe ? Colors.indigo.shade600 : Colors.white),
                                                borderRadius: BorderRadius.circular(16).copyWith(
                                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                                                  bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                                                ),
                                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    msg.isDeletedForEveryone ? '🚫 This message was deleted' : msg.content,
                                                    style: TextStyle(
                                                      color: msg.isDeletedForEveryone ? Colors.grey.shade600 : (isMe ? Colors.white : Colors.black87),
                                                      fontStyle: msg.isDeletedForEveryone ? FontStyle.italic : FontStyle.normal,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        msg.createdAt != null ? DateFormat('h:mm a').format(msg.createdAt!) : '',
                                                        style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                                                      ),
                                                      if (isMe && !msg.isDeletedForEveryone) ...[
                                                        const SizedBox(width: 4),
                                                        Icon(
                                                          msg.status == 'read' ? Icons.done_all : Icons.check, 
                                                          size: 14, 
                                                          color: msg.status == 'read' ? (isMe ? Colors.lightBlueAccent : Colors.blue) : (isMe ? Colors.white70 : Colors.grey)
                                                        )
                                                      ]
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(color: Colors.indigo.shade600, shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white),
                                    onPressed: _sendMessage,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                )
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildSidebarList() {
    final existingUserIds = <String>{};
    for (var r in _rooms) {
      for (var p in r.participants) {
        existingUserIds.add(p.id);
      }
    }
    
    final filteredRooms = _rooms.where((r) {
      if (_sidebarSearchQuery.isEmpty) return true;
      final other = _getOtherParticipant(r);
      if (other == null) return false;
      return other.name.toLowerCase().contains(_sidebarSearchQuery) || other.email.toLowerCase().contains(_sidebarSearchQuery);
    }).toList();
    
    final filteredDirectory = _sidebarSearchQuery.isEmpty ? <UserModel>[] : _directoryUsers.where((u) {
      if (existingUserIds.contains(u.id)) return false;
      return u.name.toLowerCase().contains(_sidebarSearchQuery) || u.email.toLowerCase().contains(_sidebarSearchQuery);
    }).toList();
    
    return ListView(
      children: [
        if (filteredRooms.isNotEmpty)
          ...filteredRooms.map((r) {
            final other = _getOtherParticipant(r);
            final isSelected = _activeRoom?.id == r.id;
            return ListTile(
              selected: isSelected,
              selectedTileColor: Colors.indigo.shade50,
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                foregroundColor: Colors.indigo.shade700,
                child: Text(other?.name[0].toUpperCase() ?? '?'),
              ),
              title: Text(other?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                r.lastMessage?.isDeletedForEveryone == true ? '🚫 Deleted' : (r.lastMessage?.content ?? 'New Chat'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: r.lastMessage?.createdAt != null 
                ? Text(DateFormat('h:mm a').format(r.lastMessage!.createdAt!), style: const TextStyle(fontSize: 12, color: Colors.grey))
                : null,
              onTap: () => _selectRoom(r),
            );
          }),
        if (filteredDirectory.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Other Users', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...filteredDirectory.map((u) => ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.grey.shade700,
              child: Text(u.name[0].toUpperCase()),
            ),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(u.email),
            onTap: () => _startNewChat(u.id),
          ))
        ]
      ],
    );
  }
}
