class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color characterColor;

  const MessageBubble({
    required this.message,
    required this.characterColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    color: characterColor,
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: AssetImage(character.imageUrl),
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
                      ? AppTheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: message.isUser ? null : const Radius.circular(4),
                    bottomRight: message.isUser ? const Radius.circular(4) : null,
                  ),
                  border: message.isUser
                      ? null
                      : Border.all(
                          color: characterColor.withOpacity(0.3),
                          width: 1,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: (message.isUser ? AppTheme.primary : characterColor)
                          .withOpacity(0.15),
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
                          color: characterColor.withOpacity(0.1),
                        ),
                      ),
                    Text(
                      message.message,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
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
                  color: AppTheme.primary.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 