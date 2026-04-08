import 'package:flutter/material.dart';
import '../../domain/entities/character.dart';

const String _imageBasePath = 'assets/images';
const String _imageExtension = '.png';

const List<CharacterTrait> _commonTraits = [
  CharacterTrait('친절함', 0.8),
  CharacterTrait('배려심', 0.8),
];

const List<CharacterInterest> _commonInterests = [
  CharacterInterest(
    category: '일본어',
    items: ['일본어 학습', '일본 문화'],
  ),
];

const Map<String, List<String>> _commonEmotionalResponses = {
  'happy': ['いいですね！', 'すごいですね！'],
  'sad': ['そうですか...', '残念ですね...'],
  'excited': ['おもしろい！', 'やってみよう！'],
};

const Map<String, String> _commonAppearance = {
  'hairStyle': '단발',
  'eyeColor': '갈색',
};

const Map<String, Map<String, Color>> _characterColors = {
  'yuna': {
    'primary': Color(0xFFFFB6B6),
    'secondary': Color(0xFFFFE3E3),
  },
  'junho': {
    'primary': Color(0xFF3949AB),
    'secondary': Color(0xFFE8EAF6),
  },
};

const Map<String, List<CharacterTrait>> _characterSpecificTraits = {
  'yuna': [
    CharacterTrait('명랑함', 0.9),
    CharacterTrait('수다스러움', 0.8),
    CharacterTrait('호기심', 0.9),
    CharacterTrait('귀여움', 0.8),
  ],
  'junho': [
    CharacterTrait('차분함', 0.85),
    CharacterTrait('듬직함', 0.9),
    CharacterTrait('유머', 0.75),
    CharacterTrait('현실적', 0.8),
  ],
};

const Map<String, List<CharacterInterest>> _characterSpecificInterests = {
  'yuna': [
    CharacterInterest(
      category: '취미',
      items: ['아이돌', '연애', '모바일 게임', 'SNS', '카페 투어', '쇼핑'],
    ),
  ],
  'junho': [
    CharacterInterest(
      category: '일상',
      items: ['개발', '애니·만화', '헬스', '게임', '일본 출장 경험', '라멘 맛집'],
    ),
  ],
};

const Map<String, Map<String, List<String>>> _characterSpecificEmotionalResponses = {
  'yuna': {
    'happy': ['わーい！', 'すごい！', 'やったー！'],
    'sad': ['えー、残念...', 'がっかり...', 'うーん...'],
    'excited': ['マジで！？', 'すごーい！', 'わくわく！'],
  },
  'junho': {
    'happy': ['いいね！', 'それな！', 'ナイス！'],
    'sad': ['ざんねん…', 'まあいいか', 'ゆっくりでOK'],
    'excited': ['おっ、いいじゃん！', 'おもしろそう！', 'やってみようぜ'],
  },
};

const Map<String, List<String>> _characterPhrases = {
  'yuna': [
    'ねぇねぇ、これって知ってる〜？✨',
    'すご〜い！トモトモ先輩、かっこいい！',
    'また一緒に勉強しよっ♡',
  ],
  'junho': [
    '現場で使うと便利だよ、これ。',
    '間違えても大丈夫。何度か言えば身につく。',
    '次は敬語バージョンもやってみる？',
  ],
};

const Map<String, String> _characterSpeechStyles = {
  'yuna': '~だよね！, え〜マジで！？, ~してみよっか！',
  'junho': '落ち着いたタメ口, 〜だよな, 〜じゃん, たまに冗談',
};

/// Short list subtitle (~20 chars, Korean UI line).
const Map<String, String> _characterTaglines = {
  'yuna': '일본어·수다 하며 같이 배워요!',
  'junho': '실무 한국어, 차분히 도와줄게요',
};

final List<Character> characters = [
  Character(
    id: 'yuna',
    name: '유우나',
    nameJp: 'ゆうな',
    nameKanji: '天音 ゆうな',
    level: '초급',
    tagline: _characterTaglines['yuna']!,
    description:
        '명랑하고 수다스러운 고등학생. 새로운 것에 흥미가 많고, 다소 덜렁대지만 귀여운 성격으로 주변을 웃게 만드는 분위기 메이커입니다.',
    age: 17,
    schoolYear: '고등학교 2학년',
    occupation: '고등학생',
    traits: [..._commonTraits, ..._characterSpecificTraits['yuna']!],
    interests: [..._commonInterests, ..._characterSpecificInterests['yuna']!],
    speechStyle: _characterSpeechStyles['yuna']!,
    primaryColor: _characterColors['yuna']!['primary']!,
    secondaryColor: _characterColors['yuna']!['secondary']!,
    hairStyle: _commonAppearance['hairStyle']!,
    hairColor: '갈색',
    eyeColor: _commonAppearance['eyeColor']!,
    outfit: '교복',
    accessories: ['리본', '스마트폰', '노트북 스티커'],
    selfReference: 'ゆうな',
    commonPhrases: _characterPhrases['yuna']!,
    emotionalResponses: {
      ..._commonEmotionalResponses,
      ..._characterSpecificEmotionalResponses['yuna']!,
    },
    imageUrl: '$_imageBasePath/yuna$_imageExtension',
    imagePath: '$_imageBasePath/yuna$_imageExtension',
  ),
  Character(
    id: 'junho',
    name: '준호',
    nameJp: 'ジュンホ',
    nameKanji: '朴 俊浩',
    level: '중급',
    tagline: _characterTaglines['junho']!,
    description:
        '서울 IT 스타트업에서 일하는 개발자. 일본 출장·애니 덕후 경험이 있어 한국어 회화를 도와 주고, 설명·노트는 日本語로 답니다. 단어장에는 말풍선의 한국어 표현이 올라가고 의미는 일본어로 적힙니다.',
    age: 29,
    schoolYear: '',
    occupation: '백엔드 개발자',
    traits: [..._commonTraits, ..._characterSpecificTraits['junho']!],
    interests: [..._commonInterests, ..._characterSpecificInterests['junho']!],
    speechStyle: _characterSpeechStyles['junho']!,
    primaryColor: _characterColors['junho']!['primary']!,
    secondaryColor: _characterColors['junho']!['secondary']!,
    hairStyle: '짧은 스포츠 컷',
    hairColor: '검은색',
    eyeColor: _commonAppearance['eyeColor']!,
    outfit: '맨투맨과 청바지',
    accessories: ['노트북', '텀블러'],
    selfReference: 'ジュンホ',
    commonPhrases: _characterPhrases['junho']!,
    emotionalResponses: {
      ..._commonEmotionalResponses,
      ..._characterSpecificEmotionalResponses['junho']!,
    },
    imageUrl: '$_imageBasePath/junho$_imageExtension',
    imagePath: '$_imageBasePath/junho$_imageExtension',
    tutorLocale: 'ko',
    koreanNationalPersona: true,
  ),
];
