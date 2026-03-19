import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/supabase/app_supabase.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/saved_expression.dart';
import '../../../../domain/repositories/saved_expression_repository.dart';
import '../../locale/l10n_context.dart';
import 'chat_bubble.dart';

class ChatList extends StatefulWidget {
  final List<ChatMessage> messages;
  final Character character;
  final bool isGenerating;
  final ScrollController scrollController;
  final String? chatRoomId;

  const ChatList({
    super.key,
    required this.messages,
    required this.character,
    required this.isGenerating,
    required this.scrollController,
    this.chatRoomId,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  bool _isFromCurrentUser(ChatMessage message) {
    final uid = AppSupabase.auth.currentUser?.id;
    if (widget.character.isDirectMessage) {
      if (message.senderId != null && uid != null) return message.senderId == uid;
      return false;
    }
    return message.role == 'user';
  }

  void _showExplanation(BuildContext context, ChatMessage message) {
    final messenger = ScaffoldMessenger.of(context);
    final translation = message.vocabulary != null && message.vocabulary!.isNotEmpty
        ? message.vocabulary!.map((v) => '${v.word}: ${v.meaning}').join('\n')
        : null;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.character.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Text(
                    context.tr('expressionExplanationTitle'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: widget.character.primaryColor,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flag, color: Colors.red, size: 20),
                      onPressed: () async {
                        const String subject = '토모토모';
                        final String body =
                            '[신고문장]\n${message.content}\n\n[신고사유]\n';
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'dime0801001@gmail.com',
                          queryParameters: {'subject': subject, 'body': body},
                        );
                        try {
                          final result = await launchUrl(
                            emailLaunchUri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!result) {
                            final gmailUri = Uri.parse(
                              'https://mail.google.com/mail/?view=cm&fs=1&to=dime0801001@gmail.com&su=$subject&body=$body',
                            );
                            await launchUrl(
                              gmailUri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } catch (e) {
                          debugPrint('Failed to launch email: $e');
                        }
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: Text(context.tr('saveToNotebook')),
                        onPressed: () async {
                          final savedMsg = context.tr('savedToNotebook');
                          try {
                            await sheetContext.read<SavedExpressionRepository>().add(
                                  SavedExpressionDraft(
                                    source: 'chat',
                                    content: message.content,
                                    explanation: message.explanation,
                                    translation: translation,
                                    roomId: widget.chatRoomId,
                                  ),
                                );
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            messenger.showSnackBar(SnackBar(content: Text(savedMsg)));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('$e')));
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey[800],
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (message.explanation != null) ...[
                      Text(
                        message.explanation!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey[700],
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (message.vocabulary != null && message.vocabulary!.isNotEmpty) ...[
                      ...message.vocabulary!.map(
                        (vocab) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    vocab.word,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  if (vocab.reading != null && vocab.reading!.isNotEmpty)
                                    Text(
                                      '(${vocab.reading})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                vocab.meaning,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.messages.length + (widget.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.messages.length) {
          return _buildLoadingIndicator();
        }
        final message = widget.messages[index];
        final isUser = _isFromCurrentUser(message);
        return ChatBubble(
          message: message,
          character: widget.character,
          isUser: isUser,
          onExplanationTap: !widget.character.isDirectMessage && message.role != 'user'
              ? () => _showExplanation(context, message)
              : null,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (widget.character.isDirectMessage) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.character.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.character.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: widget.character.hasAvatar ? widget.character.imageProvider : null,
              child: !widget.character.hasAvatar
                  ? Text(
                      widget.character.name.isNotEmpty ? widget.character.name.substring(0, 1) : '?',
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoadingDot(0),
                const SizedBox(width: 8),
                _buildLoadingDot(1),
                const SizedBox(width: 8),
                _buildLoadingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final opacity = (value + delay) % 1.0;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.character.primaryColor.withValues(alpha: opacity * 0.8),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
