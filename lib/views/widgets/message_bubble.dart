import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../models/chat_message.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Character character;
  final Color characterColor;

  const MessageBubble({
    required this.message,
    required this.character,
    required this.characterColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageCode = context.read<SettingsViewModel>().currentLanguage.code;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(character.imageUrl),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? characterColor : Colors.white,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: isUser ? null : const Radius.circular(4),
                    bottomRight: isUser ? const Radius.circular(4) : null,
                  ),
                  border: isUser ? null : Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  message.message,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 4,
                  left: 4,
                  right: 4,
                ),
                child: Text(
                  DateFormatter.getMessageTime(message.timestamp, languageCode),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 