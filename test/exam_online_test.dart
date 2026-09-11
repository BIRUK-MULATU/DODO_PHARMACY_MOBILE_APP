// Exercises the online-mode rework of ExamScreen (see `_slotFor`/
// `_ensureLoaded` in `lib/screens/exam_screen.dart`): a free question fetches
// and renders normally, a question past the free window comes back locked
// with no content at all (enforced server-side, not just hidden by the UI —
// see backend/README.md's "The paywall"), and answering still updates
// progress.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/models.dart';
import 'package:dodo_pharmacy_mobile_app/screens/exam_screen.dart';

import 'support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late AppState state;
  late ExamPack pack;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend()
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 3000,
        'priceBirr': 550,
        'freeLimit': 2,
      });
    for (var i = 0; i < 2; i++) {
      backend.questions.add({
        'id': 'q-$i',
        'packId': 'exit-3000',
        'number': i + 1,
        'total': 3000,
        'prompt': 'Prompt $i?',
        'options': ['Right', 'Wrong'],
        'correctIndex': 0,
        'explanation': 'Because $i.',
      });
    }
    state = AppState()..apiClientFactory = backend.client;
    await state.authSignUp(
      name: 'Sam',
      username: 'sam',
      email: 'sam@example.com',
      password: 'secret123',
      phone: '',
    );
    pack = state.examPacks.single;
  });

  Future<void> pumpExam(WidgetTester tester) async {
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(home: ExamScreen(pack: pack)),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a free question fetches from the server and renders normally',
      (tester) async {
    await pumpExam(tester);

    expect(find.text('Prompt 0?'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('Wrong'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'a question past the free window comes back locked, not fabricated locally',
      (tester) async {
    await pumpExam(tester);

    // Jump straight to an index past freeLimit (2) via the grid navigator's
    // underlying jump — simplest is tapping Next repeatedly without
    // answering, which is exactly the original paywall-bypass bug this app
    // was fixed for.
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Locked'), findsOneWidget);
    expect(find.textContaining('Go to Payment'), findsOneWidget);
    // The real prompt/answer never rendered for a locked index.
    expect(find.textContaining('Prompt'), findsNothing);
  });

  testWidgets('answering a free question updates progress on the backend',
      (tester) async {
    await pumpExam(tester);

    await tester.tap(find.text('Right'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.answered(pack.id), 1);
    expect(state.correct(pack.id), 1);
    await tester.pump(const Duration(milliseconds: 200));
    final progress =
        backend.users['sam@example.com']!['progress'] as Map<String, dynamic>;
    expect(progress[pack.id], {'answered': 1, 'correct': 1});
  });
}
