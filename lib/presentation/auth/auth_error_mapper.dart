import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n/app_strings.dart';

/// Localized + detailed text for login/signup failures.
String formatSignUpError(Object error, String languageCode) =>
    _formatAuthError(error, languageCode, isSignUp: true);

String formatLoginError(Object error, String languageCode) =>
    _formatAuthError(error, languageCode, isSignUp: false);

String _formatAuthError(Object error, String languageCode, {required bool isSignUp}) {
  if (error is AuthException) {
    return _formatAuthException(error, languageCode, isSignUp: isSignUp);
  }
  return _formatNonAuthException(error, languageCode, isSignUp: isSignUp);
}

String _formatAuthException(AuthException e, String languageCode, {required bool isSignUp}) {
  if (e is AuthWeakPasswordException && e.reasons.isNotEmpty) {
    return e.reasons.join('\n');
  }

  final code = e.code;
  if (code != null) {
    final fromCode = _messageForAuthErrorCode(code, languageCode, isSignUp: isSignUp);
    if (fromCode != null) return fromCode;
  }

  final msg = e.message.trim();
  if (msg.isNotEmpty) {
    return msg;
  }

  return AppStrings.of(languageCode, isSignUp ? 'signUpFailed' : 'loginFailed');
}

String? _messageForAuthErrorCode(String code, String languageCode, {required bool isSignUp}) {
  switch (code) {
    case 'user_already_exists':
    case 'email_exists':
      return AppStrings.of(languageCode, 'authErrorEmailAlreadyRegistered');
    case 'signup_disabled':
      return AppStrings.of(languageCode, 'authErrorSignUpDisabled');
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
    case 'over_sms_send_rate_limit':
      return AppStrings.of(languageCode, 'authErrorRateLimit');
    case 'email_not_confirmed':
      return AppStrings.of(languageCode, 'authErrorConfirmEmail');
    case 'invalid_credentials':
    case 'user_not_found':
      return AppStrings.of(languageCode, 'authErrorInvalidCredentials');
    case 'email_provider_disabled':
    case 'provider_disabled':
      return AppStrings.of(languageCode, 'authErrorProviderDisabled');
    default:
      return null;
  }
}

String _formatNonAuthException(Object error, String languageCode, {required bool isSignUp}) {
  if (error is SocketException) {
    return AppStrings.of(languageCode, 'authNetworkUnreachable');
  }
  final s = error.toString();
  if (s.contains('Failed host lookup') ||
      s.contains('SocketException') ||
      s.contains('Connection refused') ||
      s.contains('Network is unreachable')) {
    return AppStrings.of(languageCode, 'authNetworkUnreachable');
  }
  final fallback = AppStrings.of(languageCode, isSignUp ? 'signUpFailed' : 'loginFailed');
  // Show raw error so mis-wrapped or parse errors are diagnosable
  if (s.length > 400) {
    return '$fallback\n\n${s.substring(0, 400)}…';
  }
  return '$fallback\n\n$s';
}
