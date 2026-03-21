import 'package:flutter/foundation.dart';

/// Bumps when the user saves a word from chat so [WordBookScreen] can reload.
class WordBookRefreshNotifier extends ChangeNotifier {
  void requestRefresh() => notifyListeners();
}
