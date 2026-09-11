// Exercises AppState's "online" code paths (authLogin/authSignUp/
// tryAutoLogin, and every CRUD/payment/progress method's background sync)
// against the fake in-memory backend in `support/fake_backend.dart` — the
// real backend (`backend/`) is covered separately by the curl walkthroughs
// in its own README, since spinning up Mongo/Express isn't appropriate for
// a `flutter test` run.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/models.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // AppState persists the auth token via shared_preferences; give every
    // test a clean, mocked plugin channel unless it seeds its own values.
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> loggedInState(
    FakeBackend backend, {
    String email = 'sam@example.com',
    String password = 'secret123',
  }) async {
    final state = AppState()..apiClientFactory = backend.client;
    await state.authSignUp(
      name: 'Sam',
      username: 'sam',
      email: email,
      password: password,
      phone: '+251900000000',
    );
    return state;
  }

  test('authSignUp/authLogin populate the catalog from the backend', () async {
    final backend = FakeBackend()
      ..tracks.add({'id': 'pharmacy', 'name': 'Pharmacy', 'figure': ''})
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 100,
        'priceBirr': 500,
        'freeLimit': 5,
      })
      ..questions.add({
        'id': 'q-1',
        'packId': 'exit-3000',
        'number': 1,
        'total': 100,
        'prompt': 'Prompt?',
        'options': ['A', 'B'],
        'correctIndex': 0,
        'explanation': 'Because.',
      })
      ..about = {
        'version': '2.0.0',
        'intro': 'Intro',
        'features': ['a'],
        'unlocking': 'u',
        'supportEmail': 'e',
        'supportTelegram': 't',
        'supportPhone': 'p',
        'footer': 'f',
      };

    final state = await loggedInState(backend);

    expect(state.isOnline, isTrue);
    expect(state.loggedIn, isTrue);
    expect(state.tracks.map((t) => t.id), contains('pharmacy'));
    expect(state.examPacks.single.title, 'Exit exam');
    // Bulk question content is admin-only now — a learner's `questions`
    // stays empty; they fetch one gated question at a time instead (see the
    // "fetchExamQuestion" tests below).
    expect(state.questions, isEmpty);
    expect(state.aboutInfo.version, '2.0.0');
    expect(state.profile.email, 'sam@example.com');
  });

  test('an admin session does bulk-load full question content', () async {
    final backend = FakeBackend()
      ..questions.add({
        'id': 'q-1',
        'packId': 'exit-3000',
        'number': 1,
        'total': 100,
        'prompt': 'Prompt?',
        'options': ['A', 'B'],
        'correctIndex': 0,
        'explanation': 'Because.',
      });
    final state = await loggedInState(backend, email: 'admin@dodomed.et');
    expect(state.questions.single.prompt, 'Prompt?');
  });

  test(
      'fetchExamQuestion hands back a locked index with no content, and an '
      'unlocked one with full content', () async {
    final backend = FakeBackend()
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 100,
        'priceBirr': 500,
        'freeLimit': 1,
      })
      ..questions.add({
        'id': 'q-1',
        'packId': 'exit-3000',
        'number': 1,
        'total': 100,
        'prompt': 'Prompt?',
        'options': ['A', 'B'],
        'correctIndex': 0,
        'explanation': 'Because.',
      });
    final state = await loggedInState(backend);
    final pack = state.examPacks.single;

    final free = await state.fetchExamQuestion(pack: pack, index: 0);
    expect(free.locked, isFalse);
    expect(free.question!.prompt, 'Prompt?');

    // freeLimit is 1 and nothing has been answered yet through the app —
    // but index 5 is still past the free window, so it must come back
    // locked with no content at all (not just hidden by the UI).
    final locked = await state.fetchExamQuestion(pack: pack, index: 5);
    expect(locked.locked, isTrue);
    expect(locked.question, isNull);
  });

  test('an admin-prefixed email gets the admin role from the backend', () async {
    final backend = FakeBackend();
    final state = await loggedInState(backend, email: 'admin@dodomed.et');
    expect(state.isAdmin, isTrue);
  });

  test('addTrack/updateTrack/deleteTrack sync to the backend', () async {
    final backend = FakeBackend();
    final state = await loggedInState(backend, email: 'admin@dodomed.et');

    state.addTrack(Track(id: state.newTrackId(), name: 'Nursing', figure: ''));
    await Future<void>.delayed(Duration.zero);
    expect(backend.tracks.single['name'], 'Nursing');
    final id = backend.tracks.single['id'] as String;

    state.updateTrack(state.trackById(id)!.copyWith(name: 'Nursing (renamed)'));
    await Future<void>.delayed(Duration.zero);
    expect(backend.tracks.single['name'], 'Nursing (renamed)');

    state.deleteTrack(id);
    await Future<void>.delayed(Duration.zero);
    expect(backend.tracks, isEmpty);
  });

  test('submitting a payment and an admin decision sync and unlock the pack', () async {
    final backend = FakeBackend();
    final state = await loggedInState(backend);
    final pack = ExamPack(
      id: 'exit-3000',
      title: 'Exit exam',
      image: '',
      questionCount: 100,
      priceBirr: 500,
      freeLimit: 5,
    );

    final req = state.submitPaymentRequest(pack: pack, bankCode: 'CBE');
    await Future<void>.delayed(Duration.zero);
    expect(backend.payments.single['packId'], 'exit-3000');

    // `submitPaymentRequest` swaps the locally-generated id for the
    // server's once the background sync completes.
    final serverId = state.paymentRequests.single.id;
    expect(serverId, isNot(req.id));

    state.decidePayment(serverId, PaymentStatus.approved);
    await Future<void>.delayed(Duration.zero);

    expect(backend.payments.single['status'], 'approved');
    expect(state.isUnlocked('exit-3000'), isTrue);
    expect(backend.users['sam@example.com']!['unlockedPacks'], contains('exit-3000'));
  });

  test('recordAnswer persists answered/correct progress to the backend',
      () async {
    final backend = FakeBackend()
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 100,
        'priceBirr': 500,
        'freeLimit': 5,
      });
    final state = await loggedInState(backend);

    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    state.recordAnswer(packId: 'exit-3000', wasCorrect: false);
    await Future<void>.delayed(Duration.zero);

    final progress =
        backend.users['sam@example.com']!['progress'] as Map<String, dynamic>;
    expect(progress['exit-3000'], {'answered': 2, 'correct': 1});
  });

  test('recordAnswer tracks a global correct-answer streak, online and off',
      () async {
    final backend = FakeBackend()
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 100,
        'priceBirr': 500,
        'freeLimit': 5,
      });
    final state = await loggedInState(backend);

    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    expect(state.currentStreak, 2);
    expect(state.bestStreak, 2);

    state.recordAnswer(packId: 'exit-3000', wasCorrect: false);
    expect(state.currentStreak, 0);
    expect(state.bestStreak, 2); // best survives the break

    await Future<void>.delayed(Duration.zero);
    final caller = backend.users['sam@example.com']!;
    expect(caller['currentStreak'], 0);
    expect(caller['bestStreak'], 2);
  });

  test('fetchDashboardActivity returns real weekly + recent activity',
      () async {
    final backend = FakeBackend()
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 100,
        'priceBirr': 500,
        'freeLimit': 5,
      });
    final state = await loggedInState(backend);

    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    state.recordAnswer(packId: 'exit-3000', wasCorrect: false);
    await Future<void>.delayed(Duration.zero);

    final activity = await state.fetchDashboardActivity();
    expect(activity.week, hasLength(7));
    expect(activity.week.last.count, 2); // today, the last entry
    expect(activity.recent, hasLength(2));
    expect(activity.recent.first.wasCorrect, isFalse); // newest first
    expect(activity.recent.last.wasCorrect, isTrue);
  });

  test('fetchRank reflects real standing; offline is always 1 of 1',
      () async {
    final backend = FakeBackend()
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 100,
        'priceBirr': 500,
        'freeLimit': 5,
      });
    final state = await loggedInState(backend);
    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    await Future<void>.delayed(Duration.zero);

    final rank = await state.fetchRank();
    expect(rank.rank, 1);
    expect(rank.totalUsers, 1);

    final offline = AppState();
    final offlineRank = await offline.fetchRank();
    expect(offlineRank.rank, 1);
    expect(offlineRank.totalUsers, 1);
  });

  test('tryAutoLogin resumes a session from a saved token', () async {
    final backend = FakeBackend();
    final first = await loggedInState(backend);
    final token = (backend.users['sam@example.com']!['token'] as String);

    SharedPreferences.setMockInitialValues({'dodomed_auth_token': token});
    final resumed = AppState()..apiClientFactory = backend.client;
    expect(resumed.loggedIn, isFalse);

    await resumed.tryAutoLogin();

    expect(resumed.loggedIn, isTrue);
    expect(resumed.profile.email, first.profile.email);
  });

  test('tryAutoLogin leaves the app logged out when there is no saved token', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState()..apiClientFactory = FakeBackend().client;
    await state.tryAutoLogin();
    expect(state.loggedIn, isFalse);
    expect(state.isOnline, isFalse);
  });

  test('the bulk book list carries metadata only, never pages or a PDF',
      () async {
    final backend = FakeBackend()
      ..books.add({
        'id': 'book-1',
        'title': 'Some Book',
        'priceBirr': 100,
        'cover': '',
        'subjects': <String>[],
        'pages': ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        'freePages': 2,
        'pdfData': null,
        'pdfName': null,
      });
    final state = await loggedInState(backend);
    final listed = state.books.single;
    expect(listed.pages, isEmpty);
    // But the true page count still shows up for the list screen's copy.
    expect(listed.pageCount, 6);
  });

  test('fetchBookDetail hands back only the free preview when locked, and '
      'the full book once unlocked', () async {
    final backend = FakeBackend()
      ..books.add({
        'id': 'book-1',
        'title': 'Some Book',
        'priceBirr': 100,
        'cover': '',
        'subjects': <String>[],
        'pages': ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        'freePages': 2,
        'pdfData': null,
        'pdfName': null,
      });
    final state = await loggedInState(backend);

    final locked = await state.fetchBookDetail('book-1');
    expect(locked.unlocked, isFalse);
    expect(locked.book.pages, ['p1', 'p2']);
    expect(locked.book.pageCount, 6); // true total, despite the truncated preview

    backend.users['sam@example.com']!['unlockedPacks'] = ['book-1'];
    final unlocked = await state.fetchBookDetail('book-1');
    expect(unlocked.unlocked, isTrue);
    expect(unlocked.book.pages, hasLength(6));
  });

  test('addBank/updateBank/deleteBank sync to the backend', () async {
    final backend = FakeBackend();
    final state = await loggedInState(backend, email: 'admin@dodomed.et');

    state.addBank(BankAccount(
      code: 'AWASH',
      name: 'Awash Bank',
      owner: 'Test Owner',
      number: '999',
    ));
    await Future<void>.delayed(Duration.zero);
    expect(backend.banks.single['name'], 'Awash Bank');

    state.updateBank(state.bankByCode('AWASH')!.copyWith(number: '111'));
    await Future<void>.delayed(Duration.zero);
    expect(backend.banks.single['number'], '111');

    state.deleteBank('AWASH');
    await Future<void>.delayed(Duration.zero);
    expect(backend.banks, isEmpty);
  });

  test(
      'banks load into AppState for a regular (non-admin) session too — '
      'needed to pick a payment method', () async {
    final backend = FakeBackend()
      ..banks.add({'id': 'CBE', 'name': 'Commercial Bank', 'owner': 'X', 'number': '1'});
    final state = await loggedInState(backend);
    expect(state.banks.single.code, 'CBE');
  });

  test('updateAboutInfo syncs the marquee/onboarding content', () async {
    final backend = FakeBackend();
    final state = await loggedInState(backend, email: 'admin@dodomed.et');

    state.updateAboutInfo(state.aboutInfo.copyWith(
      marqueeText: 'New promo',
      onboardingSubtitle: 'New subtitle',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(backend.about!['marqueeText'], 'New promo');
    expect(backend.about!['onboardingSubtitle'], 'New subtitle');
  });

  test(
      'addPack/updatePack sync a pack\'s own About Questions content to the '
      'backend', () async {
    final backend = FakeBackend();
    final state = await loggedInState(backend, email: 'admin@dodomed.et');

    state.addPack(ExamPack(
      id: state.newPackId(),
      title: 'New Pack',
      image: '',
      questionCount: 100,
      priceBirr: 50,
      freeLimit: 5,
      aboutSummary: 'A summary',
      aboutBullets: ['Bullet A'],
      coreCourses: ['Course A'],
    ));
    await Future<void>.delayed(Duration.zero);

    final synced = backend.packs.last;
    expect(synced['aboutSummary'], 'A summary');
    expect(synced['aboutBullets'], ['Bullet A']);
    expect(synced['coreCourses'], ['Course A']);
  });
}
