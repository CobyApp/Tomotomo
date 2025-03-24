import 'package:flutter/material.dart';
import '../models/character.dart';

final List<Character> characters = [
  Character(
    id: 'shiroko',
    name: '시로코',
    imageUrl: 'assets/images/characters/shiroko.png',
    primaryColor: const Color(0xFF7BB5E3),
    description: '은발의 미스터리한 전교 회장',
    personality: '차분하고 지적이며 신중한 성격의 소유자',
    firstMessage: '안녕하세요. 저는 시로코입니다. 무엇을 도와드릴까요?',
  ),
  Character(
    id: 'akane',
    name: '아카네',
    imageUrl: 'assets/images/characters/akane.png',
    primaryColor: const Color(0xFFFF6B6B),
    description: '활기 넘치는 응원부 에이스',
    personality: '밝고 긍정적이며 에너지가 넘치는 성격',
    firstMessage: '헤이! 아카네예요~ 오늘도 즐겁게 이야기해요!',
  ),
  Character(
    id: 'yuzuki',
    name: '유즈키',
    imageUrl: 'assets/images/characters/yuzuki.png',
    primaryColor: const Color(0xFF9775FA),
    description: '전통 무용부의 프리마돈나',
    personality: '우아하고 성숙한 분위기의 소유자',
    firstMessage: '안녕하세요. 유즈키입니다. 함께 이야기 나누어요.',
  ),
  Character(
    id: 'makoto',
    name: '마코토',
    imageUrl: 'assets/images/characters/makoto.png',
    primaryColor: const Color(0xFF51CF66),
    description: '친절한 학생회 부회장',
    personality: '다정하고 신뢰감 있는 성격',
    firstMessage: '안녕하세요! 마코토입니다. 편하게 대화해요!',
  ),
]; 