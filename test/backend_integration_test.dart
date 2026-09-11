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
    expect(state.questions.single.prompt, 'Prompt?');
    expect(state.aboutInfo.version, '2.0.0');
    expect(state.profile.email, 'sam@example.com');
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

  test('recordAnswer persists answered/correct progress to the backend', () async {
    final backend = FakeBackend();
    final state = await loggedInState(backend);

    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    state.recordAnswer(packId: 'exit-3000', wasCorrect: false);
    await Future<void>.delayed(Duration.zero);

    final progress =
        backend.users['sam@example.com']!['progress'] as Map<String, dynamic>;
    expect(progress['exit-3000'], {'answered': 2, 'correct': 1});
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
}
