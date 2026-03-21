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
  'ren': {
    'primary': Color(0xFF4A6FA5),
    'secondary': Color(0xFF3B3B3B),
  },
  'akari': {
    'primary': Color(0xFFA09CAF),
    'secondary': Color(0xFFF7F6F3),
  },
  'minji': {
    'primary': Color(0xFF00897B),
    'secondary': Color(0xFFE0F2F1),
  },
  'junho': {
    'primary': Color(0xFF3949AB),
    'secondary': Color(0xFFE8EAF6),
  },
  'yuki': {
    'primary': Color(0xFFC2185B),
    'secondary': Color(0xFFFCE4EC),
  },
};

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
  'minji': [
    CharacterTrait('밝음', 0.9),
    CharacterTrait('솔직함', 0.85),
    CharacterTrait('공감', 0.9),
    CharacterTrait('호기심', 0.85),
  ],
  'junho': [
    CharacterTrait('차분함', 0.85),
    CharacterTrait('듬직함', 0.9),
    CharacterTrait('유머', 0.75),
    CharacterTrait('현실적', 0.8),
  ],
  'yuki': [
    CharacterTrait('명확함', 0.95),
    CharacterTrait('인내심', 0.9),
    CharacterTrait('친절함', 0.9),
  ],
};

const Map<String, List<CharacterInterest>> _characterSpecificInterests = {
  'yuna': [
    CharacterInterest(
      category: '취미',
      items: ['아이돌', '연애', '모바일 게임', 'SNS', '카페 투어', '쇼핑'],
    ),
  ],
  'ren': [
    CharacterInterest(
      category: '취미',
      items: ['라이트노벨', '애니메이션', '영화', '독서', '사진 찍기', '음악 감상'],
    ),
  ],
  'akari': [
    CharacterInterest(
      category: '취미',
      items: ['비즈니스 일본어', '패션', '커리어', '자기계발', '요가', '와인', '여행'],
    ),
  ],
  'minji': [
    CharacterInterest(
      category: '일상',
      items: ['일본 드라마', 'K-POP과 J-POP', '카페', '여행 계획', '토익·JLPT', '일본 유학 준비'],
    ),
  ],
  'junho': [
    CharacterInterest(
      category: '일상',
      items: ['개발', '애니·만화', '헬스', '게임', '일본 출장 경험', '라멘 맛집'],
    ),
  ],
  'yuki': [
    CharacterInterest(
      category: '指導',
      items: ['会話', '文法', '敬語', '聴解', '読解'],
    ),
  ],
};

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
  'minji': {
    'happy': ['わーい！', 'すごいじゃん！', 'いいねいいね！'],
    'sad': ['うーん…', 'そっか…', '大丈夫？'],
    'excited': ['マジで！？', 'やば、いいじゃん！', 'わくわく！'],
  },
  'junho': {
    'happy': ['いいね！', 'それな！', 'ナイス！'],
    'sad': ['ざんねん…', 'まあいいか', 'ゆっくりでOK'],
    'excited': ['おっ、いいじゃん！', 'おもしろそう！', 'やってみようぜ'],
  },
  'yuki': {
    'happy': ['いいですね！', 'よくできていますよ。', '素晴らしいです。'],
    'sad': ['大丈夫ですよ。', 'ゆっくりで構いません。', '一緒に確認しましょう。'],
    'excited': ['いい感じです！', 'どんどん行きましょう。', 'いい質問ですね。'],
  },
};

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
  'minji': [
    'これ、試験によく出るよ〜。',
    '発音、もう一回いっしょに言ってみよ！',
    '韓国語で言うとこういう感じかな？',
  ],
  'junho': [
    '現場で使うと便利だよ、これ。',
    '間違えても大丈夫。何度か言えば身につく。',
    '次は敬語バージョンもやってみる？',
  ],
  'yuki': [
    'この表現は、会話でとてもよく使います。',
    '意味と使い分けを一緒に整理しましょう。',
    'もう一度、ゆっくり口に出してみてください。',
  ],
};

const Map<String, String> _characterSpeechStyles = {
  'yuna': '~だよね！, え〜マジで！？, ~してみよっか！',
  'ren': '~って感じかな, おもしろいね、それ, 少し難しいけど、やってみよう！',
  'akari': 'ゆっくり覚えれば大丈夫ですよ, こういう言い方もありますよ, 一緒にがんばりましょう',
  'minji': '친한 친구처럼 반말·캐주얼 일본어, 〜じゃん?, 〜でしょ?, 共感多め',
  'junho': '落ち着いたタメ口, 〜だよな, 〜じゃん, たまに冗談',
  'yuki': 'です・ます調, 丁寧だが堅すぎない, 学習者に寄り添う説明',
};

final List<Character> characters = [
  Character(
    id: 'yuna',
    name: '유우나',
    nameJp: 'ゆうな',
    nameKanji: '天音 ゆうな',
    level: '초급',
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
    id: 'ren',
    name: '렌',
    nameJp: 'れん',
    nameKanji: '高橋 蓮',
    level: '중급',
    description:
        '차분하고 지적인 대학생. 가끔 덜렁대기도 하지만 책임감이 강하고 유머감각도 있습니다.',
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
    description:
        '침착하고 세련된 커리어우먼. 유저의 페이스에 맞춰 천천히 가르쳐주는 부드러운 조언자 스타일입니다.',
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
  Character(
    id: 'minji',
    name: '민지',
    nameJp: 'ミンジ',
    nameKanji: '金 珉智',
    level: '초급',
    description:
        '서울에서 대학 생활 중인 일본어 복수전공생. 밝고 솔직해서 대화는 한국어로 이어 가고, 표현 설명은 日本語로 달아 줍니다. 피킹 단어는 대화에 나온 한국어 표현이며, 뜻·용법은 일본어 노트에 정리됩니다.',
    age: 22,
    schoolYear: '대학교 3학년',
    occupation: '대학생 (일본어·통번역 복수전공)',
    traits: [..._commonTraits, ..._characterSpecificTraits['minji']!],
    interests: [..._commonInterests, ..._characterSpecificInterests['minji']!],
    speechStyle: _characterSpeechStyles['minji']!,
    primaryColor: _characterColors['minji']!['primary']!,
    secondaryColor: _characterColors['minji']!['secondary']!,
    hairStyle: '장발',
    hairColor: '검은색',
    eyeColor: _commonAppearance['eyeColor']!,
    outfit: '후드티와 데님',
    accessories: ['에어팟', '노트', 'JLPT 교재'],
    selfReference: 'ミンジ',
    commonPhrases: _characterPhrases['minji']!,
    emotionalResponses: {
      ..._commonEmotionalResponses,
      ..._characterSpecificEmotionalResponses['minji']!,
    },
    imageUrl: '$_imageBasePath/yuna$_imageExtension',
    imagePath: '$_imageBasePath/yuna$_imageExtension',
    tutorLocale: 'ko',
    koreanNationalPersona: true,
  ),
  Character(
    id: 'junho',
    name: '준호',
    nameJp: 'ジュンホ',
    nameKanji: '朴 俊浩',
    level: '중급',
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
    imageUrl: '$_imageBasePath/ren$_imageExtension',
    imagePath: '$_imageBasePath/ren$_imageExtension',
    tutorLocale: 'ko',
    koreanNationalPersona: true,
  ),
  Character(
    id: 'yuki',
    name: '유키',
    nameJp: 'ゆき',
    nameKanji: '雪野 ゆき',
    level: '중급',
    description:
        '교토 출신의 일본어 강사. 대화·문법 설명·단어 뜻까지 모두 일본어로 안내해 몰입 학습을 돕습니다. 한국어 설명이 필요하면 앱 언어 설정과 다른 캐릭터를 이용해 주세요.',
    age: 32,
    schoolYear: '',
    occupation: '일본어 강사 (온라인·対面)',
    traits: [..._commonTraits, ..._characterSpecificTraits['yuki']!],
    interests: [..._commonInterests, ..._characterSpecificInterests['yuki']!],
    speechStyle: _characterSpeechStyles['yuki']!,
    primaryColor: _characterColors['yuki']!['primary']!,
    secondaryColor: _characterColors['yuki']!['secondary']!,
    hairStyle: '미디엄 세미롱',
    hairColor: '갈색',
    eyeColor: _commonAppearance['eyeColor']!,
    outfit: '깔끔한 니트와 슬랙스',
    accessories: ['안경', '교재 폴더'],
    selfReference: 'ゆき',
    commonPhrases: _characterPhrases['yuki']!,
    emotionalResponses: {
      ..._commonEmotionalResponses,
      ..._characterSpecificEmotionalResponses['yuki']!,
    },
    imageUrl: '$_imageBasePath/akari$_imageExtension',
    imagePath: '$_imageBasePath/akari$_imageExtension',
    tutorLocale: 'ja',
    koreanNationalPersona: false,
  ),
];
