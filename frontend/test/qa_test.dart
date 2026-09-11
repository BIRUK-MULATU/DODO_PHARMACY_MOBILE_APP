// The "Q&A" feature: a learner asks a question from the drawer's Q&A
// screen, an admin answers it from the admin panel's own Q&A page, and the
// answer shows back up for the learner — professionally presented, not just
// a raw text dump.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/models.dart';
import 'package:dodo_pharmacy_mobile_app/screens/qa_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/admin/admin_qa_screen.dart';

import 'support/fake_backend.dart';

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

  group('AppState online methods', () {
    test('askQuestion adds locally then swaps in the real server id', () async {
      final backend = FakeBackend();
      final learner = await _signedInLearner(backend);

      learner.askQuestion('How do I reset my password?');
      expect(learner.qaItems.first.question, 'How do I reset my password?');
      expect(learner.qaItems.first.status, QaStatus.pending);
      final localId = learner.qaItems.first.id;

      await Future<void>.delayed(Duration.zero);
      expect(learner.qaItems.first.id, isNot(localId));
      expect(learner.qaItems.first.id, backend.qaQuestions.single['id']);
    });

    test('askQuestion ignores a blank question', () async {
      final state = AppState();
      final before = state.qaItems.length;
      state.askQuestion('   ');
      expect(state.qaItems.length, before);
    });

    test('fetchMyQuestions replaces the local list with the real thread', () async {
      final backend = FakeBackend();
      final learner = await _signedInLearner(backend);
      await _signedInLearner(backend, name: 'Other Learner', email: 'other@example.com');

      learner.askQuestion('Only mine should come back');
      await Future<void>.delayed(Duration.zero);

      // A totally fresh AppState signed into the same account, so its
      // qaItems starts as the offline demo seed — proves fetchMyQuestions
      // genuinely replaces it rather than merging.
      final freshSession = AppState()..apiClientFactory = backend.client;
      await freshSession.authLogin(email: 'sam@example.com', password: 'secret123');
      await freshSession.fetchMyQuestions();

      expect(freshSession.qaItems, hasLength(1));
      expect(freshSession.qaItems.single.question, 'Only mine should come back');
    });

    test('fetchAllQuestions (admin) sees every learner, pending first', () async {
      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      final learnerA = await _signedInLearner(backend);
      final learnerB =
          await _signedInLearner(backend, name: 'Learner B', email: 'b@example.com');

      learnerA.askQuestion('Question from A');
      await Future<void>.delayed(Duration.zero);
      learnerB.askQuestion('Question from B');
      await Future<void>.delayed(Duration.zero);

      final all = await admin.fetchAllQuestions();
      expect(all, hasLength(2));
      // Newest-first among equally-pending items.
      expect(all.first.question, 'Question from B');
      expect(all.every((q) => q.status == QaStatus.pending), isTrue);

      await admin.answerQuestion(id: all.first.id, answer: 'Here you go.');
      final afterAnswer = await admin.fetchAllQuestions();
      // The still-pending one now sorts first.
      expect(afterAnswer.first.question, 'Question from A');
      expect(afterAnswer.first.status, QaStatus.pending);
      expect(afterAnswer.last.status, QaStatus.answered);
    });

    test('a learner cannot fetch the admin bulk list', () async {
      final backend = FakeBackend();
      final learner = await _signedInLearner(backend);
      expect(() => learner.fetchAllQuestions(), throwsException);
    });

    test('answerQuestion online updates status and is visible to the learner',
        () async {
      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      final learner = await _signedInLearner(backend);

      learner.askQuestion('Can I get a refund?');
      await Future<void>.delayed(Duration.zero);
      final id = learner.qaItems.first.id;

      final updated = await admin.answerQuestion(
        id: id,
        answer: 'Refunds are handled within 3 business days — just message support.',
      );
      expect(updated.status, QaStatus.answered);
      expect(updated.answeredAt, isNotNull);

      await learner.fetchMyQuestions();
      expect(learner.qaItems.single.status, QaStatus.answered);
      expect(learner.qaItems.single.answer, contains('3 business days'));
    });

    test('answerQuestion rejects a blank answer', () async {
      final state = AppState();
      final id = state.qaItems.first.id;
      expect(
        () => state.answerQuestion(id: id, answer: '   '),
        throwsA(isA<Exception>()),
      );
    });

    test('answerQuestion offline updates the local demo thread', () async {
      final state = AppState();
      final pending =
          state.qaItems.firstWhere((q) => q.status == QaStatus.pending);

      final updated = await state.answerQuestion(id: pending.id, answer: 'Yes, offline too.');

      expect(updated.status, QaStatus.answered);
      expect(state.qaItems.firstWhere((q) => q.id == pending.id).answer,
          'Yes, offline too.');
    });

    test('deleteQuestionThread removes it for everyone', () async {
      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      final learner = await _signedInLearner(backend);

      learner.askQuestion('Delete me');
      await Future<void>.delayed(Duration.zero);
      final id = learner.qaItems.first.id;

      admin.deleteQuestionThread(id);
      await Future<void>.delayed(Duration.zero);

      final all = await admin.fetchAllQuestions();
      expect(all.where((q) => q.id == id), isEmpty);
    });
  });

  group('QaScreen (learner-facing)', () {
    Widget host(AppState state) => AppStateScope(
          state: state,
          child: const MaterialApp(home: QaScreen()),
        );

    testWidgets('offline: shows the demo thread with a professional answer card',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(host(AppState()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Answered'), findsOneWidget);
      expect(find.text('DODOMED Support'), findsOneWidget);
      expect(find.textContaining('Access is granted'), findsOneWidget);
    });

    testWidgets('typing a question and tapping Send adds it to the list',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState();
      await tester.pumpWidget(host(state));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
          find.byType(TextField), 'Does the price ever change?');
      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Does the price ever change?'), findsOneWidget);
      expect(find.textContaining('question was sent'), findsOneWidget);
      expect(state.qaItems.first.question, 'Does the price ever change?');
    });

    testWidgets('an empty question does nothing', (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState();
      final before = state.qaItems.length;
      await tester.pumpWidget(host(state));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(state.qaItems.length, before);
      expect(tester.takeException(), isNull);
    });
  });

  group('AdminQaScreen', () {
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
  });
}
