import 'character.dart';

class ChatMessage {
  final String content;
  final String role;
  final DateTime timestamp;
  final String? explanation;
  final List<Vocabulary>? vocabulary;

  /// Default welcome message for a character. Single place for content and vocabulary.
  static ChatMessage welcomeFor(Character character) {
    return ChatMessage(
      content: '${character.nameJp}です。よろしくお願いします！',
      role: 'assistant',
      timestamp: DateTime.now(),
      explanation:
          '기본적인 자기소개 표현입니다.\n- 〜です: ~입니다\n- よろしくお願いします: 잘 부탁드립니다',
      vocabulary: [
        Vocabulary(word: 'よろしく', reading: 'よろしく', meaning: '잘 부탁드립니다'),
        Vocabulary(word: 'お願い', reading: 'おねがい', meaning: '부탁'),
      ],
    );
  }

  ChatMessage({
    required this.content,
    required this.role,
    required this.timestamp,
    this.explanation,
    this.vocabulary,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'role': role,
        'timestamp': timestamp.toIso8601String(),
        'explanation': explanation,
        'vocabulary': vocabulary?.map((v) => v.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        content: json['content'] as String,
        role: json['role'] as String,
        timestamp: DateTime.parse(json['timestamp']),
        explanation: json['explanation'] as String?,
        vocabulary: json['vocabulary'] != null
            ? (json['vocabulary'] as List)
                .map((v) => Vocabulary.fromJson(v as Map<String, dynamic>))
                .toList()
            : null,
      );
}

class Vocabulary {
  final String word;
  final String? reading;
  final String meaning;

  Vocabulary({
    required this.word,
    this.reading,
    required this.meaning,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'reading': reading,
      'meaning': meaning,
    };
  }

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      word: json['word'] as String,
      reading: json['reading'] as String?,
      meaning: json['meaning'] as String,
    );
  }
}
