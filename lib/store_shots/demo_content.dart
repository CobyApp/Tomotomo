/// Demo content for the store-screenshot entry point (`main_store_shots.dart`).
///
/// Screenshot-only: nothing here is reachable from a release build.
///
/// Each locale gets its own set because a listing has to be believable in the
/// language it is read in. The friend speaks the STUDY language and the
/// translation line is in the UI language, which is exactly how the app behaves
/// — a Korean speaker learning Japanese sees Japanese with Korean underneath.
library;

class DemoTurn {
  const DemoTurn({
    required this.text,
    required this.fromLearner,
    this.translation,
    this.explanation,
  });

  final String text;
  final bool fromLearner;
  final String? translation;
  final String? explanation;
}

class DemoFriend {
  const DemoFriend({
    required this.id,
    required this.name,
    required this.tagline,
    required this.speechStyle,
    required this.level,
    required this.avatarAsset,
    required this.language,
  });

  final String id;
  final String name;
  final String tagline;
  final String speechStyle;
  final String level;
  final String avatarAsset;

  /// Each friend has their own, so the friends screenshot shows the language
  /// chips differing down the list — which is the feature the listing is for.
  /// Tagging a Chinese-named friend with a Japanese chip, as a single shared
  /// study language did, read as a bug.
  final String language;
}

class DemoWord {
  const DemoWord({
    required this.term,
    required this.reading,
    required this.meaning,
  });

  final String term;
  final String reading;
  final String meaning;
}

class DemoContent {
  const DemoContent({
    required this.learnerName,
    required this.studyLanguage,
    required this.friends,
    required this.conversation,
    required this.words,
  });

  final String learnerName;
  final String studyLanguage;
  final List<DemoFriend> friends;
  final List<DemoTurn> conversation;
  final List<DemoWord> words;
}

const String _img = 'assets/images';

/// Learning Japanese — used by the Korean, English and Chinese listings, which
/// differ only in the translation line and the learner's name.
List<DemoFriend> _japaneseFriends() => const [
  DemoFriend(
    id: 'shot-yuna',
    name: 'ゆうな',
    tagline: 'カフェ巡りと猫が好き',
    speechStyle: 'やさしい話し方',
    level: 'beginner',
    avatarAsset: '$_img/yuna.png',
    language: 'ja',
  ),
  DemoFriend(
    id: 'shot-emily',
    name: 'Emily',
    tagline: 'Talks about films and food',
    speechStyle: 'Warm and chatty',
    level: 'intermediate',
    avatarAsset: '$_img/emily.png',
    language: 'en',
  ),
  DemoFriend(
    id: 'shot-lina',
    name: '李娜',
    tagline: '喜欢旅行和摄影',
    speechStyle: '温柔的语气',
    level: 'beginner',
    avatarAsset: '$_img/lina.png',
    language: 'zh',
  ),
];

List<DemoFriend> _koreanFriends() => const [
  DemoFriend(
    id: 'shot-junho',
    name: '준호',
    tagline: '농구랑 라면을 좋아해요',
    speechStyle: '편하게 반말로',
    level: 'beginner',
    avatarAsset: '$_img/junho.png',
    language: 'ko',
  ),
  DemoFriend(
    id: 'shot-emily',
    name: 'Emily',
    tagline: 'Talks about films and food',
    speechStyle: 'Warm and chatty',
    level: 'intermediate',
    avatarAsset: '$_img/emily.png',
    language: 'en',
  ),
  DemoFriend(
    id: 'shot-wangwei',
    name: '王伟',
    tagline: '爱看球，也爱做饭',
    speechStyle: '直爽',
    level: 'intermediate',
    avatarAsset: '$_img/wangwei.png',
    language: 'zh',
  ),
];

/// The same Japanese conversation, with the translation line in [uiLang].
List<DemoTurn> _japaneseConversation(String uiLang) {
  final under = <String, List<String>>{
    'ko': [
      '오늘 학교 어땠어?',
      '수업이 좀 길었는데, 점심은 맛있었어!',
      '뭐 먹었어?',
      '카레! 매웠지만 맛있었어.',
    ],
    'en': [
      'How was school today?',
      'Class ran long, but lunch was good!',
      'What did you have?',
      'Curry! Spicy, but tasty.',
    ],
    'zh': [
      '今天学校怎么样？',
      '课有点长，不过午饭很好吃！',
      '你吃了什么？',
      '咖喱！有点辣，但很好吃。',
    ],
  }[uiLang]!;

  return [
    DemoTurn(text: '今日、学校どうだった？', fromLearner: true, translation: under[0]),
    DemoTurn(
      text: '授業はちょっと長かったけど、お昼はおいしかったよ！',
      fromLearner: false,
      translation: under[1],
      explanation: '「〜けど」で前と後ろをやわらかくつなげています。',
    ),
    DemoTurn(text: '何を食べたの？', fromLearner: true, translation: under[2]),
    DemoTurn(
      text: 'カレー！ちょっと辛かったけど、おいしかった。',
      fromLearner: false,
      translation: under[3],
      explanation: '「ちょっと」は程度をやわらげる言い方です。',
    ),
  ];
}

/// A Korean conversation for the Japanese listing.
List<DemoTurn> _koreanConversation() => const [
  DemoTurn(text: '오늘 뭐 했어?', fromLearner: true, translation: '今日は何をしたの？'),
  DemoTurn(
    text: '친구랑 농구했어! 완전 재밌었어.',
    fromLearner: false,
    translation: '友だちとバスケをしたよ！すごく楽しかった。',
    explanation: '「완전」は「すごく」に近い、くだけた強調です。',
  ),
  DemoTurn(text: '나도 같이 하고 싶다', fromLearner: true, translation: '私も一緒にやりたいな'),
  DemoTurn(
    text: '다음에 같이 가자! 내가 알려줄게.',
    fromLearner: false,
    translation: '今度いっしょに行こう！ぼくが教えてあげる。',
    explanation: '「-을게」は話し手の意思をやわらかく伝えます。',
  ),
];

List<DemoWord> _japaneseWords(String uiLang) {
  final meanings = <String, List<String>>{
    'ko': ['수업', '맛있다', '조금', '즐겁다'],
    'en': ['class, lesson', 'delicious', 'a little', 'fun, enjoyable'],
    'zh': ['课，课程', '好吃', '一点点', '开心，快乐'],
  }[uiLang]!;
  return [
    DemoWord(term: '授業', reading: 'じゅぎょう', meaning: meanings[0]),
    DemoWord(term: 'おいしい', reading: 'おいしい', meaning: meanings[1]),
    DemoWord(term: 'ちょっと', reading: 'ちょっと', meaning: meanings[2]),
    DemoWord(term: '楽しい', reading: 'たのしい', meaning: meanings[3]),
  ];
}

List<DemoWord> _koreanWords() => const [
  DemoWord(term: '농구', reading: 'ノング', meaning: 'バスケットボール'),
  DemoWord(term: '재밌다', reading: 'チェミッタ', meaning: 'おもしろい'),
  DemoWord(term: '완전', reading: 'ワンジョン', meaning: 'すごく、完全に'),
  DemoWord(term: '알려주다', reading: 'アルリョジュダ', meaning: '教えてあげる'),
];

/// The demo set for a UI language.
DemoContent demoContentFor(String uiLang) => switch (uiLang) {
  // A Japanese speaker learning Korean.
  'ja' => DemoContent(
    learnerName: 'あかり',
    studyLanguage: 'ko',
    friends: _koreanFriends(),
    conversation: _koreanConversation(),
    words: _koreanWords(),
  ),
  'en' => DemoContent(
    learnerName: 'Sam',
    studyLanguage: 'ja',
    friends: _japaneseFriends(),
    conversation: _japaneseConversation('en'),
    words: _japaneseWords('en'),
  ),
  'zh' => DemoContent(
    learnerName: '小雨',
    studyLanguage: 'ja',
    friends: _japaneseFriends(),
    conversation: _japaneseConversation('zh'),
    words: _japaneseWords('zh'),
  ),
  // Korean UI, learning Japanese.
  _ => DemoContent(
    learnerName: '도영',
    studyLanguage: 'ja',
    friends: _japaneseFriends(),
    conversation: _japaneseConversation('ko'),
    words: _japaneseWords('ko'),
  ),
};
