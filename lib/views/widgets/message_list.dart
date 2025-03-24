import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';
import '../../viewmodels/settings_viewmodel.dart';
// import 'package:intl/intl.dart';  // 주석 처리

class MessageList extends StatefulWidget {
  final ScrollController scrollController;

  const MessageList({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatViewModel, SettingsViewModel>(
      builder: (context, viewModel, settingsVM, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients && viewModel.messages.isNotEmpty) {
            widget.scrollController.animateTo(
              widget.scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        if (viewModel.messages.isEmpty) {
          return const Center(child: Text('메시지가 없습니다.'));
        }

        // 목록을 GestureDetector로 감싸서 클릭 이벤트 감지
        return GestureDetector(
          // 화면 터치 시 키보드 닫기
          onTap: () {
            // 현재 포커스 해제 (키보드 닫기)
            FocusScope.of(context).unfocus();
          },
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: viewModel.messages.length,
            itemBuilder: (context, index) {
              final message = viewModel.messages[index];
              final member = viewModel.currentMember;
              
              return Align(
                alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!message.isUser) ...[
                        // 캐릭터 미니 프로필
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8, bottom: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: member.primaryColor,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: AssetImage(member.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: message.isUser 
                                ? member.primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomLeft: message.isUser ? null : const Radius.circular(4),
                              bottomRight: message.isUser ? const Radius.circular(4) : null,
                            ),
                            border: message.isUser
                                ? null
                                : Border.all(
                                    color: member.primaryColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: member.primaryColor.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (!message.isUser)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: Icon(
                                    Icons.favorite,
                                    size: 24,
                                    color: member.primaryColor.withOpacity(0.1),
                                  ),
                                ),
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: message.isUser 
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (message.isUser) ...[
                        // 사용자 메시지 전송 상태
                        Container(
                          margin: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: member.primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
} 