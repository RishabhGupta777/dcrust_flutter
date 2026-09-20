import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      drawer: const AppDrawer(),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.rooms.isEmpty) {
            return const Center(child: Text('No chat rooms found.'));
          }
          
          final currentUser = context.read<AuthProvider>().user;
          
          return ListView.builder(
            itemCount: provider.rooms.length,
            itemBuilder: (context, index) {
              final room = provider.rooms[index];
              final otherUsers = room.participants.where((u) => u.id != currentUser?.id).toList();
              final roomName = otherUsers.isNotEmpty ? otherUsers.map((u) => u.name).join(', ') : 'Empty Room';
              
              return ListTile(
                leading: CircleAvatar(child: Text(roomName.isNotEmpty ? roomName[0] : '?')),
                title: Text(roomName),
                subtitle: Text(room.lastMessage?.content ?? 'No messages yet'),
                onTap: () {
                  context.push('/chat/${room.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
