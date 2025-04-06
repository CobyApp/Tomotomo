import 'package:flutter/material.dart';
import '../models/character.dart';

// 공통 상수 정의
const String _imageBasePath = 'assets/images';
const String _imageExtension = '.png';

// 공통 특성 정의
const List<CharacterTrait> _commonTraits = [
  CharacterTrait('친절함', 0.8),
  CharacterTrait('배려심', 0.8),
];

// 공통 관심사 정의
const List<CharacterInterest> _commonInterests = [
  CharacterInterest(
    category: '일본어',
    items: ['일본어 학습', '일본 문화'],
  ),
];

// 공통 감정 반응 정의
const Map<String, List<String>> _commonEmotionalResponses = {
  'happy': ['いいですね！', 'すごいですね！'],
  'sad': ['そうですか...', '残念ですね...'],
  'excited': ['おもしろい！', 'やってみよう！'],
};

// 공통 외형 속성 정의
const Map<String, String> _commonAppearance = {
  'hairStyle': '단발',
  'eyeColor': '갈색',
};

// 캐릭터별 색상 정의
const Map<String, Map<String, Color>> _characterColors = {
  'yuna': {
    'primary': Color(0xFFFFB6B6),
    'secondary': Color(0xFFFFE3E3),
  },
  'ren': {
    'primary': Color(0xFF4A6FA5),
    'secondary': Color(0xFF3B3B3B),
  },
  'akari': {
    'primary': Color(0xFFA09CAF),
    'secondary': Color(0xFFF7F6F3),
  },
};

// 캐릭터별 특성 정의
const Map<String, List<CharacterTrait>> _characterSpecificTraits = {
  'yuna': [
    CharacterTrait('명랑함', 0.9),
    CharacterTrait('수다스러움', 0.8),
    CharacterTrait('호기심', 0.9),
    CharacterTrait('귀여움', 0.8),
  ],
  'ren': [
    CharacterTrait('차분함', 0.8),
    CharacterTrait('지적임', 0.9),
    CharacterTrait('책임감', 0.9),
    CharacterTrait('유머감각', 0.7),
  ],
  'akari': [
    CharacterTrait('침착함', 0.9),
    CharacterTrait('세련됨', 0.9),
    CharacterTrait('전문성', 0.9),
  ],
};

// 캐릭터별 관심사 정의
const Map<String, List<CharacterInterest>> _characterSpecificInterests = {
  'yuna': [
    CharacterInterest(
      category: '취미',
      items: [
        '아이돌',
        '연애',
        '모바일 게임',
        'SNS',
        '카페 투어',
        '쇼핑',
      ],
    ),
  ],
  'ren': [
    CharacterInterest(
      category: '취미',
      items: [
        '라이트노벨',
        '애니메이션',
        '영화',
        '독서',
        '사진 찍기',
        '음악 감상',
      ],
    ),
  ],
  'akari': [
    CharacterInterest(
      category: '취미',
      items: [
        '비즈니스 일본어',
        '패션',
        '커리어',
        '자기계발',
        '요가',
        '와인',
        '여행',
      ],
    ),
  ],
};

// 캐릭터별 감정 반응 정의
const Map<String, Map<String, List<String>>> _characterSpecificEmotionalResponses = {
  'yuna': {
    'happy': ['わーい！', 'すごい！', 'やったー！'],
    'sad': ['えー、残念...', 'がっかり...', 'うーん...'],
    'excited': ['マジで！？', 'すごーい！', 'わくわく！'],
  },
  'ren': {
    'happy': ['なるほど！', '面白いね！', 'いいね！'],
    'sad': ['そうか...', '難しいね...', 'うーん...'],
    'excited': ['おもしろい！', 'すごい発見だね！', 'やってみよう！'],
  },
  'akari': {
    'happy': ['素晴らしいですね！', 'よくできました！', 'お見事です！'],
    'sad': ['大丈夫ですよ。', '焦らなくてもいいですよ。', 'ゆっくり行きましょう。'],
    'excited': ['素敵ですね！', 'いいですね！', '素晴らしい発見です！'],
  },
};

// 캐릭터별 대사 정의
const Map<String, List<String>> _characterPhrases = {
  'yuna': [
    'ねぇねぇ、これって知ってる〜？✨',
    'すご〜い！トモトモ先輩、かっこいい！',
    'また一緒に勉強しよっ♡',
  ],
  'ren': [
    'これは"て形"って言うんだ。面白いよね。',
    '大丈夫、少しずつ慣れていけばOK。',
    '例文で一緒に確認してみよう。',
  ],
  'akari': [
    '〜でございます、という表現は丁寧ですね。',
    'よろしければ、もう一度復習してみましょう。',
    '敬語は難しいですが、慣れればきっと楽しいですよ。',
  ],
};

// 캐릭터별 말투 정의
const Map<String, String> _characterSpeechStyles = {
  'yuna': '~だよね！, え〜マジで！？, ~してみよっか！',
  'ren': '~って感じかな, おもしろいね、それ, 少し難しいけど、やってみよう！',
  'akari': 'ゆっくり覚えれば大丈夫ですよ, こういう言い方もありますよ, 一緒にがんばりましょう',
};

final List<Character> characters = [
  Character(
    id: 'yuna',
    name: '유우나',
    nameJp: 'ゆうな',
    nameKanji: '天音 ゆうな',
    level: '초급',
    description: '명랑하고 수다스러운 고등학생. 새로운 것에 흥미가 많고, 다소 덜렁대지만 귀여운 성격으로 주변을 웃게 만드는 분위기 메이커입니다.',
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
    id: 'ren',
    name: '렌',
    nameJp: 'れん',
    nameKanji: '高橋 蓮',
    level: '중급',
    description: '차분하고 지적인 대학생. 가끔 덜렁대기도 하지만 책임감이 강하고 유머감각도 있습니다.',
    age: 21,
    schoolYear: '대학교 3학년',
    occupation: '대학생 (문학부 전공)',
    traits: [..._commonTraits, ..._characterSpecificTraits['ren']!],
    interests: [..._commonInterests, ..._characterSpecificInterests['ren']!],
    speechStyle: _characterSpeechStyles['ren']!,
    primaryColor: _characterColors['ren']!['primary']!,
    secondaryColor: _characterColors['ren']!['secondary']!,
    hairStyle: _commonAppearance['hairStyle']!,
    hairColor: '검은색',
    eyeColor: _commonAppearance['eyeColor']!,
    outfit: '캐주얼',
    accessories: ['안경', '책', '커피잔'],
    selfReference: 'れん',
    commonPhrases: _characterPhrases['ren']!,
    emotionalResponses: {
      ..._commonEmotionalResponses,
      ..._characterSpecificEmotionalResponses['ren']!,
    },
    imageUrl: '$_imageBasePath/ren$_imageExtension',
    imagePath: '$_imageBasePath/ren$_imageExtension',
  ),
  Character(
    id: 'akari',
    name: '아카리',
    nameJp: 'あかり',
    nameKanji: '白石 あかり',
    level: '고급',
    description: '침착하고 세련된 커리어우먼. 유저의 페이스에 맞춰 천천히 가르쳐주는 부드러운 조언자 스타일입니다.',
    age: 28,
    schoolYear: '',
    occupation: '외국계 IT기업 마케터',
    traits: [..._commonTraits, ..._characterSpecificTraits['akari']!],
    interests: [..._commonInterests, ..._characterSpecificInterests['akari']!],
    speechStyle: _characterSpeechStyles['akari']!,
    primaryColor: _characterColors['akari']!['primary']!,
    secondaryColor: _characterColors['akari']!['secondary']!,
    hairStyle: _commonAppearance['hairStyle']!,
    hairColor: '검은색',
    eyeColor: _commonAppearance['eyeColor']!,
    outfit: '비즈니스 캐주얼',
    accessories: ['노트북', '명함', '커피컵'],
    selfReference: 'あかり',
    commonPhrases: _characterPhrases['akari']!,
    emotionalResponses: {
      ..._commonEmotionalResponses,
      ..._characterSpecificEmotionalResponses['akari']!,
    },
    imageUrl: '$_imageBasePath/akari$_imageExtension',
    imagePath: '$_imageBasePath/akari$_imageExtension',
  ),
]; 