import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/characters.dart';
import '../../models/character.dart';
import '../../services/chat_storage.dart';
import '../../services/ai_service.dart';
import '../screens/chat_screen.dart';
import '../../services/ad_service.dart';

class CharacterListScreen extends StatelessWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トモトモ'),
        centerTitle: false,
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: character.primaryColor.withOpacity(0.03),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          _onCharacterTap(context, character);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: character.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: character.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: DecorationImage(
                    image: AssetImage(character.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: character.primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          character.level,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        character.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        character.nameJp,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          color: Colors.grey[600],
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    character.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.6,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: character.interests
                        .where((interest) => interest.category == '취미')
                        .expand((interest) => interest.items)
                        .map((item) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: character.primaryColor,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: character.primaryColor.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: character.primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCharacterTap(BuildContext context, Character character) {
    AdService().showAdOnCharacterSelect();
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
  }
} 