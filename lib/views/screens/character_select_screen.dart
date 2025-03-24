import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/characters.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../utils/localization.dart';
import '../../views/screens/settings_screen.dart';

class CharacterSelectScreen extends StatelessWidget {
  const CharacterSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final settingsVM = context.watch<SettingsViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectCharacter),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: characters.length,
        itemBuilder: (context, index) {
          final character = characters[index];
          return GestureDetector(
            onTap: () {
              context.read<ChatViewModel>().setCurrentMember(
                character,
                settingsVM.currentLanguage.code,
              );
              Navigator.pushNamed(context, '/chat');
            },
            child: Container(
              decoration: BoxDecoration(
                color: character.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: character.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: AssetImage(character.imageUrl),
                    backgroundColor: character.primaryColor.withOpacity(0.2),
                    onBackgroundImageError: (exception, stackTrace) {
                      debugPrint('이미지 로드 오류: $exception');
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    character.getName(settingsVM.currentLanguage.code),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: character.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      character.getDescription(settingsVM.currentLanguage.code),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 