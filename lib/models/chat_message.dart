class ChatMessage {
  final String content;
  final String role;
  final DateTime timestamp;
  final String? explanation;
  final List<Vocabulary>? vocabulary;

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