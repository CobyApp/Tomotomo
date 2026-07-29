import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:aichat/data/character/characters_data.dart';
import 'package:aichat/presentation/chat/widgets/chat_input.dart';
import 'package:aichat/domain/repositories/profile_repository.dart';
import 'package:aichat/presentation/locale/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// context.tr resolves through LocaleNotifier, whose default is Korean — the
/// per-language strings are covered by the localization parity tests, so this
/// file asserts the Korean rendering.
final class _StubProfiles implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnsupportedError('${i.memberName}');
}

/// The generation registry is in memory, so iOS terminating the app during the
/// multi-second inference loses the reply: the learner's message is already on
/// disk and the room came back to unexplained silence — no error, no typing
/// state, nothing to tap. This is the affordance that replaces the silence.
void main() {
  Widget host({
    required bool showRetry,
    bool isGenerating = false,
    VoidCallback? onRetry,
  }) => ChangeNotifierProvider<LocaleNotifier>(
    create: (_) => LocaleNotifier(_StubProfiles()),
    child: MaterialApp(
      theme: PaperTheme.light,
      locale: const Locale('en'),
      home: Scaffold(
        body: ChatInput(
          controller: TextEditingController(),
          onSend: () {},
          isGenerating: isGenerating,
          character: characters.first,
          showRetry: showRetry,
          onRetry: onRetry,
        ),
      ),
    ),
  );

  testWidgets('offers a retry when a reply never arrived', (tester) async {
    await tester.pumpWidget(host(showRetry: true, onRetry: () {}));
    expect(find.text('답장이 오지 않았어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('tapping it asks again', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(showRetry: true, onRetry: () => taps++));
    await tester.tap(find.text('다시 시도'));
    expect(taps, 1);
  });

  testWidgets('stays hidden in the normal case', (tester) async {
    await tester.pumpWidget(host(showRetry: false, onRetry: () {}));
    expect(find.text('다시 시도'), findsNothing);
    expect(find.text('답장이 오지 않았어요.'), findsNothing);
  });

  testWidgets('hidden while a reply is actually being generated', (tester) async {
    await tester.pumpWidget(
      host(showRetry: true, isGenerating: true, onRetry: () {}),
    );
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('the composer still works with the notice showing', (tester) async {
    await tester.pumpWidget(host(showRetry: true, onRetry: () {}));
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello');
    expect(find.text('hello'), findsOneWidget);
  });
}
