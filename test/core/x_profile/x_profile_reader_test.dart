import 'package:aichat/core/x_profile/x_profile_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts and requests a large X profile avatar', () {
    const markdown =
        '[![Image: user avatar]('
        'https://pbs.twimg.com/profile_images/12345/avatar_normal.jpg'
        ')](https://x.com/example/photo)';

    final result = XProfileReader.extractProfileImageUrlFromText(markdown);

    expect(result, isNotNull);
    expect(result, startsWith('https://pbs.twimg.com/profile_images/12345/'));
    expect(result, contains('name=400x400'));
  });

  test('supports query-based profile image URLs without an extension', () {
    const text =
        'https://pbs.twimg.com/profile_images/98765/avatar?format=jpg&name=normal';

    final result = XProfileReader.extractProfileImageUrlFromText(text);

    expect(result, contains('format=jpg'));
    expect(result, contains('name=400x400'));
  });
}
