import 'dart:io';

import 'package:aichat/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// AppStrings.of falls back to `?? key`, so calling tr() with a key that does not
/// exist puts the raw key on screen — in every language — and nothing catches it:
/// the key is a runtime string, so the compiler is happy, and the parity test
/// only compares the four maps against each other, which a key missing from all
/// four passes. This is the check that fails instead.
///
/// Only literal keys are checked. Keys assembled at runtime cannot be resolved
/// here, so they are skipped rather than reported as missing.
void main() {
  test('every literal string key used in the app exists', () {
    final known = AppStrings.all('ko').keys.toSet();
    final call = RegExp(
      r"""(?:\.tr|\.trRead|AppStrings\.of)\(\s*(?:[A-Za-z0-9_.]+\s*,\s*)?'([A-Za-z][A-Za-z0-9_]*)'""",
    );

    final missing = <String, Set<String>>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final m in call.allMatches(file.readAsStringSync())) {
        final key = m.group(1)!;
        if (!known.contains(key)) {
          missing.putIfAbsent(file.path, () => <String>{}).add(key);
        }
      }
    }

    expect(missing, isEmpty, reason: 'keys with no string: $missing');
  });

  test('the check can actually see the call sites it is meant to guard', () {
    // A regex that silently matches nothing would make the test above pass no
    // matter what, so pin that it finds a known key in a known file.
    final src = File(
      'lib/presentation/main_shell/tabs/characters_tab.dart',
    ).readAsStringSync();
    expect(src, contains("tr('charactersEmptyTitle')"));
    expect(
      RegExp(r"""\.tr\(\s*'([A-Za-z][A-Za-z0-9_]*)'""")
          .allMatches(src)
          .map((m) => m.group(1))
          .toSet(),
      contains('charactersEmptyTitle'),
    );
  });
}
