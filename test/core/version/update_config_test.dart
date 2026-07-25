import 'dart:convert';

import 'package:aichat/core/version/update_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateUpdate', () {
    const config = RemoteVersionConfig(minBuild: 3, latestBuild: 5);

    test('below min_build is forced', () {
      expect(
        evaluateUpdate(currentBuild: 2, config: config),
        UpdateStatus.forced,
      );
    });

    test('at min_build but below latest is recommended', () {
      expect(
        evaluateUpdate(currentBuild: 3, config: config),
        UpdateStatus.recommended,
      );
      expect(
        evaluateUpdate(currentBuild: 4, config: config),
        UpdateStatus.recommended,
      );
    });

    test('at or above latest is ok', () {
      expect(evaluateUpdate(currentBuild: 5, config: config), UpdateStatus.ok);
      expect(evaluateUpdate(currentBuild: 9, config: config), UpdateStatus.ok);
    });
  });

  group('RemoteVersionConfig.tryParse', () {
    test('parses a well-formed config with store url', () {
      final cfg = RemoteVersionConfig.tryParse(
        jsonDecode('{"min_build":1,"latest_build":4,"store_url":"https://x"}'),
      );
      expect(cfg, isNotNull);
      expect(cfg!.minBuild, 1);
      expect(cfg.latestBuild, 4);
      expect(cfg.storeUrl, 'https://x');
    });

    test('accepts string numbers and treats blank store url as null', () {
      final cfg = RemoteVersionConfig.tryParse(
        jsonDecode('{"min_build":"2","latest_build":"7","store_url":"  "}'),
      );
      expect(cfg!.minBuild, 2);
      expect(cfg.latestBuild, 7);
      expect(cfg.storeUrl, isNull);
    });

    test('returns null when required fields are missing or malformed', () {
      expect(RemoteVersionConfig.tryParse(jsonDecode('{"min_build":1}')), isNull);
      expect(RemoteVersionConfig.tryParse(jsonDecode('"nope"')), isNull);
      expect(RemoteVersionConfig.tryParse(null), isNull);
    });
  });
}
