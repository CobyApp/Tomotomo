import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/characters.dart';
import '../../models/character.dart';
import '../../services/chat_storage_service.dart';
import '../../services/ai_service.dart';
import '../screens/chat_screen.dart';

class CharacterListScreen extends StatelessWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('토모토모'),
        centerTitle: false,
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            return _buildCharacterCard(context, character);
          },
        ),
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, Character character) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                character: character,
                chatStorage: context.read<ChatStorage>(),
                aiService: context.read<AIService>(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(character.imagePath),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${character.name} (${character.nameJp})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      character.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: character.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        character.level,
                        style: TextStyle(
                          color: character.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 