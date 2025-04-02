import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../data/characters.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../views/screens/chat_screen.dart';
import '../../services/chat_storage_service.dart';
import '../../services/ai_service.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class CharacterSelectScreen extends StatelessWidget {
  final ChatStorageService chatStorage;
  final AIService aiService;

  const CharacterSelectScreen({
    super.key, 
    required this.chatStorage,
    required this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    Future.microtask(() {
      if (kDebugMode) {
        for (var character in characters) {
          chatStorage.getLastMessage(character.id).then((message) {
            print('Last message for ${character.name}: ${message?.content}');
          });
        }
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '일본어 학습 챗봇',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.blue,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: characters.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _buildCharacterItem(context, characters[index]),
      ),
    );
  }

  Widget _buildCharacterItem(BuildContext context, Character character) {
    return FutureBuilder<ChatMessage?>(
      future: chatStorage.getLastMessage(character.id),
      builder: (context, snapshot) {
        final lastMessage = snapshot.data;
        
        return ListTile(
          leading: GestureDetector(
            onTap: () => _showCharacterInfo(context, character),
            child: Hero(
              tag: 'character_${character.id}',
              child: CircleAvatar(
                backgroundImage: AssetImage(character.imageUrl),
                radius: 28,
              ),
            ),
          ),
          title: Text(character.name),
          subtitle: Text(
            lastMessage?.content ?? '아직 메시지가 없습니다',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: lastMessage != null ? Text(
            _formatMessageTime(lastMessage.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ) : null,
          onTap: () => _onCharacterSelected(context, character),
        );
      },
    );
  }

  void _showCharacterInfo(BuildContext context, Character character) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: AssetImage(character.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        character.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: character.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${character.age}세',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    character.nameKanji,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    character.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _onCharacterSelected(context, character);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: character.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '대화 시작하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      final weekday = time.weekday;
      final days = ['월', '화', '수', '목', '금', '토', '일'];
      return '${days[weekday - 1]}요일';
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }

  void _onCharacterSelected(BuildContext context, Character character) {
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