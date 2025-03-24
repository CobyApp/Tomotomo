import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../data/characters.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../utils/localization.dart';
import '../../views/screens/settings_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../views/screens/chat_screen.dart';

class CharacterSelectScreen extends StatelessWidget {
  const CharacterSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<SettingsViewModel>().currentLanguage.code;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          _getAppName(languageCode),
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.primary,
            onPressed: () => Navigator.pushNamed(context, AppConstants.settingsRoute),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: characters.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _buildCharacterItem(context, characters[index]),
      ),
    );
  }

  Widget _buildCharacterItem(BuildContext context, Character character) {
    return InkWell(
      onTap: () => _onCharacterSelected(context, character),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 프로필 이미지
            GestureDetector(
              onTap: () => _showCharacterInfo(context, character),
              child: Hero(
                tag: 'character_${character.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(character.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 캐릭터 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLastMessage(character, context),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 시간 표시
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getLastMessageTime(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCharacterInfo(BuildContext context, Character character) {
    final languageCode = context.read<SettingsViewModel>().currentLanguage.code;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 이미지
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
                // 닫기 버튼
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
            // 캐릭터 정보
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름과 나이
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
                  // 일본어 이름
                  Text(
                    character.nameKanji,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 설명
                  Text(
                    character.getDescription(languageCode),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 대화하기 버튼
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
                      child: Text(
                        _getChatButtonText(languageCode),
                        style: const TextStyle(
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

  String _getChatButtonText(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return 'チャットを始める';
      case 'en':
        return 'Start Chat';
      default:
        return '대화 시작하기';
    }
  }

  String _getLastMessage(Character character, BuildContext context) {
    final languageCode = context.read<SettingsViewModel>().currentLanguage.code;
    
    switch (languageCode) {
      case 'ja':
        return 'タップしてチャットを開始';
      case 'en':
        return 'Tap to start chat';
      default:
        return '탭하여 채팅 시작하기';
    }
  }

  String _getLastMessageTime(BuildContext context) {
    // TODO: 실제 마지막 메시지 시간으로 교체
    return '';  // 처음에는 시간 표시 안함
  }

  void _onCharacterSelected(BuildContext context, Character character) {
    final aiService = context.read<ChatViewModel>().aiService;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            character: character,
            aiService: aiService,
          ),
          child: const ChatScreen(),
        ),
      ),
    );
  }

  String _getAppName(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return AppConstants.appNameJa;
      case 'en':
        return AppConstants.appNameEn;
      default:
        return AppConstants.appNameKo;
    }
  }
} 