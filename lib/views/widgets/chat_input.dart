import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';
import '../../viewmodels/settings_viewmodel.dart';

class ChatInput extends StatefulWidget {
  final String hintText;
  final Color primaryColor;
  final Function(String) onSendMessage;
  final VoidCallback onMessageSent;

  const ChatInput({
    Key? key,
    required this.hintText,
    required this.primaryColor,
    required this.onSendMessage,
    required this.onMessageSent,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final message = _controller.text;
    if (message.trim().isNotEmpty) {
      widget.onSendMessage(message);
      _controller.clear();
      setState(() {});
      
      widget.onMessageSent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? widget.primaryColor
                        : _hasText 
                            ? widget.primaryColor.withOpacity(0.5)
                            : Colors.grey[300]!,
                    width: _focusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (text) {
                      setState(() {
                        _hasText = text.trim().isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      filled: false,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                    cursorColor: widget.primaryColor,
                    maxLines: 1,
                    minLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _hasText 
                    ? widget.primaryColor
                    : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: _hasText ? [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(21),
                  onTap: _hasText ? _handleSubmit : null,
                  child: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: _hasText ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}