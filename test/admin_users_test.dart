// The admin "Users" page: a real, dated activity log per account, and
// direct admin open/close control over any user's access to any pack or
// book — independent of (and able to override) the payment-approval flow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/admin/admin_user_detail_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/admin/admin_users_screen.dart';

import 'support/fake_backend.dart';

Widget _host(AppState state, Widget home) => AppStateScope(
      state: state,
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    );

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
  // authSignUp persists the session token via shared_preferences — needs a
  // mock store installed or it throws MissingPluginException (see the other
  // online-mode test files, e.g. dashboard_online_test.dart).
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppState online methods', () {
    test('fetchAllUsers lists every real account', () async {
      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      await _signedInLearner(backend);

      final users = await admin.fetchAllUsers();

      expect(users.length, 2);
      expect(users.map((u) => u.email), containsAll(['admin@example.com', 'sam@example.com']));
      expect(users.firstWhere((u) => u.email == 'admin@example.com').isAdmin, isTrue);
      expect(users.firstWhere((u) => u.email == 'sam@example.com').isAdmin, isFalse);
    });

    test('fetchUserActivity reflects a learner\'s real recorded answers', () async {
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
      final admin = await _signedInAdmin(backend);
      final learner = await _signedInLearner(backend);
      // recordAnswer syncs fire-and-forget — give the fake network call a
      // beat to land before reading the admin-side activity back.
      learner.recordAnswer(packId: 'exit-3000', wasCorrect: true);
      await Future<void>.delayed(Duration.zero);
      learner.recordAnswer(packId: 'exit-3000', wasCorrect: false);
      await Future<void>.delayed(Duration.zero);

      final users = await admin.fetchAllUsers();
      final learnerSummary = users.firstWhere((u) => u.email == 'sam@example.com');
      final activity = await admin.fetchUserActivity(learnerSummary.id);

      expect(activity.user.totalAnswered, 2);
      expect(activity.user.totalCorrect, 1);
      expect(activity.week.length, 7);
      expect(activity.week.last.count, 2);
      expect(activity.recent, hasLength(2));
      expect(activity.recent.first.packTitle, 'Exit exam');
    });

    test('a learner cannot fetch the users list', () async {
      final backend = FakeBackend();
      final learner = await _signedInLearner(backend);

      expect(() => learner.fetchAllUsers(), throwsException);
    });

    test('setUserAccess opens then closes a pack for a specific user', () async {
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
      final admin = await _signedInAdmin(backend);
      await _signedInLearner(backend);
      final users = await admin.fetchAllUsers();
      final learnerId = users.firstWhere((u) => u.email == 'sam@example.com').id;

      final afterOpen = await admin.setUserAccess(
        userId: learnerId,
        packId: 'exit-3000',
        unlock: true,
      );
      expect(afterOpen, contains('exit-3000'));

      final afterClose = await admin.setUserAccess(
        userId: learnerId,
        packId: 'exit-3000',
        unlock: false,
      );
      expect(afterClose, isNot(contains('exit-3000')));
    });
  });

  group('Admin Users screens', () {
    Future<void> pumpAndSettleQuiet(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('offline shows a clear notice instead of a broken list',
        (tester) async {
      final state = AppState();
      await tester.pumpWidget(_host(state, const AdminUsersScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('only exist with the backend connected'), findsOneWidget);
    });

    testWidgets('lists real accounts and opens a user\'s detail page',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      await _signedInLearner(backend);

      await tester.pumpWidget(_host(admin, const AdminUsersScreen()));
      await pumpAndSettleQuiet(tester);

      expect(find.text('Sam Learner'), findsOneWidget);
      expect(find.text('Ada Admin'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);

      await tester.tap(find.text('Sam Learner'));
      await pumpAndSettleQuiet(tester);

      expect(find.byType(AdminUserDetailScreen), findsOneWidget);
      expect(find.text('Access — open or close any pack or book'), findsOneWidget);
    });

    testWidgets('toggling a pack open on the detail screen calls through to the backend',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      final admin = await _signedInAdmin(backend);
      await _signedInLearner(backend);
      final learnerSummary = (await admin.fetchAllUsers())
          .firstWhere((u) => u.email == 'sam@example.com');

      await tester.pumpWidget(
        _host(admin, AdminUserDetailScreen(user: learnerSummary)),
      );
      await pumpAndSettleQuiet(tester);

      expect(find.text('Exit exam'), findsOneWidget);
      expect(find.text('Closed'), findsWidgets);

      await tester.tap(find.byType(Switch).first);
      await pumpAndSettleQuiet(tester);

      expect(find.text('Open'), findsWidgets);

      final refreshed = await admin.fetchUserActivity(learnerSummary.id);
      expect(refreshed.user.unlockedPacks, contains('exit-3000'));
    });
  });
}
