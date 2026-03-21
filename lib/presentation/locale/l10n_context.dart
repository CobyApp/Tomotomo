import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import 'locale_notifier.dart';

extension L10nBuildContext on BuildContext {
  /// Localized string; rebuilds when [LocaleNotifier] changes.
  String tr(String key, {Map<String, String>? params}) {
    final code = watch<LocaleNotifier>().languageCode;
    return AppStrings.of(code, key, params: params);
  }

  /// Use in [onPressed], [Future] callbacks, etc. — must not call [watch] outside [build].
  String trRead(String key, {Map<String, String>? params}) {
    final code = read<LocaleNotifier>().languageCode;
    return AppStrings.of(code, key, params: params);
  }
}
