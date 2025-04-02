import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../data/characters.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../services/chat_storage_service.dart';
import '../../services/ai_service.dart';
import '../../models/chat_message.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  final ChatStorageService chatStorage;
  final AIService aiService;

  const ChatListScreen({
    super.key, 
    required this.chatStorage,
    required this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '일본어 학습 채팅',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: characters.length,
        itemBuilder: (context, index) => _buildChatItem(context, characters[index]),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Character character) {
    return FutureBuilder<ChatMessage?>(
      future: chatStorage.getLastMessage(character.id),
      builder: (context, snapshot) {
        final lastMessage = snapshot.data;
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(character.imageUrl),
            backgroundColor: character.primaryColor.withOpacity(0.1),
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image: $exception');
              // 이미지 로드 실패 시 기본 이미지 사용
            },
          ),
          title: Row(
            children: [
              Text(
                character.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLevelColor(character.level),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  character.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                lastMessage?.content ?? '${character.nameJp}と日本語で話しましょう！',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: lastMessage != null ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMessageTime(lastMessage.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ) : null,
          onTap: () => _openChatScreen(context, character),
        );
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '초급':
        return Colors.green;
      case '중급':
        return Colors.blue;
      case '고급':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      final days = ['월', '화', '수', '목', '금', '토', '일'];
      return '${days[time.weekday - 1]}요일';
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }

  void _openChatScreen(BuildContext context, Character character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            character: character,
            chatStorage: chatStorage,
            aiService: aiService,
          ),
          child: const ChatScreen(),
        ),
      ),
    );
  }
} 