import 'package:flutter/material.dart';
import '../../models/character.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isGenerating;
  final Character character;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    required this.isGenerating,
    required this.character,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: widget.character.primaryColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: widget.character.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              enabled: !widget.isGenerating,
              onSubmitted: _handleSubmit,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.send,
              color: widget.isGenerating 
                ? Colors.grey 
                : widget.character.primaryColor,
            ),
            onPressed: widget.isGenerating 
              ? null 
              : () => _handleSubmit(_textController.text),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(String text) {
    if (text.trim().isEmpty) return;
    widget.onSendMessage(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}