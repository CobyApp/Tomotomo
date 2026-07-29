import 'package:aichat/core/version/update_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// The forced-update screen cannot be dismissed, and its only button opened
/// whatever URL a remote JSON file supplied. Unvalidated, that pairs a hard block
/// with an arbitrary destination — a phishing page wearing the app's credibility.
void main() {
  test('real store listings are allowed', () {
    for (final url in const [
      'https://apps.apple.com/app/id123456789',
      'https://itunes.apple.com/app/id1',
      'https://play.google.com/store/apps/details?id=com.dime.tomotomo',
      'itms-apps://itunes.apple.com/app/id1',
      'market://details?id=com.dime.tomotomo',
    ]) {
      expect(isAllowedStoreUrl(url), isTrue, reason: url);
    }
  });

  test('anything else is refused', () {
    for (final url in const [
      'https://evil.example/verify-your-apple-id',
      'https://apps.apple.com.evil.example/app/id1',
      'https://play.google.com.attacker.test/x',
      'http://apps.apple.com/app/id1', // plain http
      'javascript:alert(1)',
      'file:///etc/passwd',
      'tel:+15551234567',
      'sms:+15551234567',
      'data:text/html,<script>',
      'com.other.app://open',
    ]) {
      expect(isAllowedStoreUrl(url), isFalse, reason: url);
    }
  });

  test('missing or unparseable values are refused, not crashed on', () {
    expect(isAllowedStoreUrl(null), isFalse);
    expect(isAllowedStoreUrl(''), isFalse);
    expect(isAllowedStoreUrl('   '), isFalse);
    expect(isAllowedStoreUrl(':::'), isFalse);
  });

  test('host matching ignores case and surrounding space', () {
    expect(isAllowedStoreUrl('  https://APPS.APPLE.COM/app/id1  '), isTrue);
  });
}
