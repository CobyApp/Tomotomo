import 'package:flutter/material.dart';
import '../models/character.dart';

final List<Character> characters = [
  Character(
    id: 'shiroko',
    names: {
      'ko': '시로코',
      'ja': 'シロコ',
      'en': 'Shiroko',
    },
    imageUrl: 'assets/images/characters/shiroko.png',
    primaryColor: const Color(0xFF7BB5E3),
    descriptions: {
      'ko': '은발의 미스터리한 전교 회장',
      'ja': '銀髪のミステリアスな生徒会長',
      'en': 'Mysterious student council president with silver hair',
    },
    personalities: {
      'ko': '차분하고 지적이며 신중한 성격의 소유자',
      'ja': '落ち着いていて知的で慎重な性格の持ち主',
      'en': 'Calm, intelligent, and thoughtful personality',
    },
    firstMessages: {
      'ko': '안녕하세요. 시로코입니다. 무엇을 도와드릴까요?',
      'ja': 'こんにちは。シロコです。何かお手伝いできることはありますか？',
      'en': 'Hello. I\'m Shiroko. How may I help you?',
    },
  ),
  Character(
    id: 'akane',
    names: {
      'ko': '아카네',
      'ja': 'アカネ',
      'en': 'Akane',
    },
    imageUrl: 'assets/images/characters/akane.png',
    primaryColor: const Color(0xFFFF6B6B),
    descriptions: {
      'ko': '활기 넘치는 응원부 에이스',
      'ja': '元気いっぱいのチアリーディング部のエース',
      'en': 'Energetic ace of the cheerleading club',
    },
    personalities: {
      'ko': '밝고 긍정적이며 에너지가 넘치는 성격',
      'ja': '明るくポジティブでエネルギッシュな性格',
      'en': 'Bright, positive, and full of energy',
    },
    firstMessages: {
      'ko': '헤이! 아카네예요~ 오늘도 즐겁게 이야기해요!',
      'ja': 'ヘイ！アカネだよ～ 今日も楽しくおしゃべりしましょう！',
      'en': 'Hey! I\'m Akane~ Let\'s have a fun chat today!',
    },
  ),
  Character(
    id: 'yuzuki',
    names: {
      'ko': '유즈키',
      'ja': '優月',
      'en': 'Yuzuki',
    },
    imageUrl: 'assets/images/characters/yuzuki.png',
    primaryColor: const Color(0xFF9775FA),
    descriptions: {
      'ko': '전통 무용부의 프리마돈나',
      'ja': '伝統舞踊部のプリマドンナ',
      'en': 'Prima donna of the traditional dance club',
    },
    personalities: {
      'ko': '우아하고 성숙한 분위기의 소유자',
      'ja': '優雅で成熟した雰囲気の持ち主',
      'en': 'Elegant and mature personality',
    },
    firstMessages: {
      'ko': '안녕하세요. 유즈키입니다. 함께 이야기 나누어요.',
      'ja': 'こんにちは。優月です。一緒にお話ししましょう。',
      'en': 'Hello. I\'m Yuzuki. Let\'s talk together.',
    },
  ),
  Character(
    id: 'makoto',
    names: {
      'ko': '마코토',
      'ja': 'マコト',
      'en': 'Makoto',
    },
    imageUrl: 'assets/images/characters/makoto.png',
    primaryColor: const Color(0xFF51CF66),
    descriptions: {
      'ko': '친절한 학생회 부회장',
      'ja': '親切な生徒会副会長',
      'en': 'Kind student council vice president',
    },
    personalities: {
      'ko': '다정하고 신뢰감 있는 성격',
      'ja': '優しくて信頼感のある性格',
      'en': 'Gentle and trustworthy personality',
    },
    firstMessages: {
      'ko': '안녕하세요! 마코토입니다. 편하게 대화해요!',
      'ja': 'こんにちは！マコトです。気軽に話しましょう！',
      'en': 'Hi! I\'m Makoto. Let\'s chat comfortably!',
    },
  ),
]; 