// The admin-facing half of the Q&A feature (AdminQaScreen) — listing every
// learner's questions and answering them inline, online and offline. The
// shared AppState-level behavior lives in
// packages/dodomed_core/test/qa_test.dart; the learner half (QaScreen)
// lives in apps/user_app/test/qa_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_admin/screens/admin/admin_qa_screen.dart';

import 'package:dodomed_core/test_support/fake_backend.dart';

Future<AppState> _signedInAdmin(FakeBackend backend) async {
  final state = AppState()..apiClientFactory = backend.client;
  await state.authSignUp(
    name: 'Ada Admin',
    username: 'ada',
    email: 'admin@example.com',
    password: 'secret123',
    phone: '',
  );
  return state;
}

Future<AppState> _signedInLearner(
  FakeBackend backend, {
  String name = 'Sam Learner',
  String email = 'sam@example.com',
}) async {
  final state = AppState()..apiClientFactory = backend.client;
  await state.authSignUp(
    name: name,
    username: name.split(' ').first.toLowerCase(),
    email: email,
    password: 'secret123',
    phone: '',
  );
  return state;
}

Future<void> pumpQuiet(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(AppState state) => AppStateScope(
        state: state,
        child: const MaterialApp(home: AdminQaScreen()),
      );

  testWidgets('offline: falls back to the demo thread and can answer inline',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await tester.pumpWidget(host(state));
    await tester.pump(const Duration(milliseconds: 300));

    final pending =
        state.qaItems.firstWhere((q) => q.status == QaStatus.pending);
    expect(find.text(pending.question), findsOneWidget);

    await tester.enterText(
        find.byType(TextField).first, 'Yes — works fully offline.');
    await tester.tap(find.text('Send answer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        state.qaItems.firstWhere((q) => q.id == pending.id).status,
        QaStatus.answered);
    expect(find.text('Yes — works fully offline.'), findsOneWidget);
  });

  testWidgets('online: answering a real question flips it to Answered',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final backend = FakeBackend();
    final admin = await _signedInAdmin(backend);
    final learner = await _signedInLearner(backend);
    learner.askQuestion('When does the next pack come out?');
    // A bare `Future.delayed` never fires inside testWidgets' fake clock
    // (only tester.pump() advances it) — runAsync escapes to real time for
    // this one microtask-flushing beat.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    await tester.pumpWidget(host(admin));
    await pumpQuiet(tester);

    expect(find.text('When does the next pack come out?'), findsOneWidget);
    expect(find.text('Sam Learner'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.enterText(
        find.byType(TextField).first, 'Next month — stay tuned!');
    await tester.tap(find.text('Send answer'));
    await pumpQuiet(tester);

    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('Next month — stay tuned!'), findsOneWidget);
  });
}
