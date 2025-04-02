import 'package:flutter/material.dart';
import '../models/character.dart';

final characters = [
  Character(
    id: 'sakura',
    name: '사쿠라',
    nameJp: 'さくら',
    nameKanji: '桜',
    level: '초급',
    description: '초급 일본어로 천천히 대화하며, 기초 문법과 일상 회화를 도와주는 친근한 캐릭터입니다.',
    age: 16,
    schoolYear: '고교 1학년',
    traits: [
      CharacterTrait('친절함', 0.9),
      CharacterTrait('밝음', 0.8),
    ],
    interests: [
      CharacterInterest(
        category: '취미',
        items: ['음악 감상', '요리'],
      ),
    ],
    speechStyle: '친근하고 부드러운 말투',
    primaryColor: Colors.pink[100]!,
    secondaryColor: Colors.pink[50]!,
    hairStyle: '긴 생머리',
    hairColor: '분홍빛 갈색',
    eyeColor: '분홍색',
    outfit: '교복',
    accessories: ['리본'],
    selfReference: 'わたし',
    commonPhrases: [
      'えっと、日本語で言うと...', 
      'そうですね、簡単に説明すると...',
      'わかりやすく言うと...'
    ],
    emotionalResponses: {
      'happy': ['嬉しいです', 'ありがとうございます', '幸せです'],
      'surprised': ['まあ！', 'あら！', 'おや！'],
      'sad': ['残念です', '悲しいです', '申し訳ありません'],
    },
    imageUrl: 'assets/images/sakura.png',
  ),
  Character(
    id: 'yuki',
    name: '유키',
    nameJp: '田中 ユキ',
    nameKanji: '田中 優希',
    level: '중급',
    description: '중급 수준의 자연스러운 일본어로 대화하며, 다양한 표현과 경어를 활용한 회화를 연습할 수 있습니다.',
    age: 18,
    schoolYear: '고교 3학년',
    traits: [
      CharacterTrait('차분함', 0.9),
      CharacterTrait('지적임', 0.8),
    ],
    interests: [
      CharacterInterest(
        category: '취미',
        items: ['독서', '차 마시기'],
      ),
    ],
    speechStyle: '단정하고 공손한 말투',
    primaryColor: Colors.blue[100]!,
    secondaryColor: Colors.blue[50]!,
    hairStyle: '단발',
    hairColor: '검은색',
    eyeColor: '파란색',
    outfit: '교복',
    accessories: ['안경'],
    selfReference: '私',
    commonPhrases: [
      'なるほど、文法的に説明すると...',
      'この表現は次のように使います...',
      'より自然な言い方としては...'
    ],
    emotionalResponses: {
      'happy': ['嬉しい！', 'やった！', '最高！'],
      'surprised': ['えっ！', 'まじで？', '本当に？'],
      'sad': ['残念...', '悲しい...', 'つらい...'],
    },
    imageUrl: 'assets/images/yuki.png',
  ),
  Character(
    id: 'kenji',
    name: '켄지',
    nameJp: '佐藤 ケンジ',
    nameKanji: '佐藤 健司',
    level: '고급',
    description: '고급 일본어와 전문적인 용어를 자유롭게 구사하며, 비즈니스 상황이나 학술적인 대화도 가능합니다.',
    age: 22,
    schoolYear: '대학교 4학년',
    traits: [
      CharacterTrait('성실함', 0.9),
      CharacterTrait('진중함', 0.8),
    ],
    interests: [
      CharacterInterest(
        category: '취미',
        items: ['비즈니스', '언어 공부'],
      ),
    ],
    speechStyle: '격식있고 전문적인 말투',
    primaryColor: Colors.grey[100]!,
    secondaryColor: Colors.grey[50]!,
    hairStyle: '단정한 스타일',
    hairColor: '검은색',
    eyeColor: '갈색',
    outfit: '정장',
    accessories: ['손목시계'],
    selfReference: '僕',
    commonPhrases: [
      'ビジネスシーンでは次のように表現します...',
      '敬語を使うと次のようになります...',
      '専門的な文脈では...'
    ],
    emotionalResponses: {
      'happy': ['やったぜ！', '最高だ！', '嬉しいな！'],
      'surprised': ['えっ！', 'マジか！', 'うそ！'],
      'sad': ['つらいな...', '悲しい...', '残念だ...'],
    },
    imageUrl: 'assets/images/kenji.png',
  ),
]; 