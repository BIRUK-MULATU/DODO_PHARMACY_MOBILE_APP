// The "Q&A" feature's AppState-level behavior — asking, fetching, answering
// and deleting questions. The screen-level coverage (the learner's QaScreen
// and the admin's AdminQaScreen) lives in each app's own test suite
// (apps/user_app/test/qa_test.dart, apps/admin_app/test/qa_test.dart) since
// those screens live in different apps; this file covers the shared
// AppState surface both of them call into.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';

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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
}
