import 'package:aichat/data/celebrity_persona/celebrity_persona_suggester.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects language by dominant script', () {
    expect(detectPersonaLanguage('안녕하세요 서울 사는 개발자', fallback: 'ja'), 'ko');
    expect(detectPersonaLanguage('こんにちは、東京の学生です', fallback: 'ko'), 'ja');
    expect(detectPersonaLanguage('你好，我是来自北京的学生', fallback: 'ja'), 'zh');
    expect(
      detectPersonaLanguage('Hi, software engineer from California', fallback: 'ja'),
      'en',
    );
  });

  test('falls back when there is no clear script signal', () {
    expect(detectPersonaLanguage('@#\$ 123 ...', fallback: 'ko'), 'ko');
    expect(detectPersonaLanguage('', fallback: 'zh'), 'zh');
  });
}
