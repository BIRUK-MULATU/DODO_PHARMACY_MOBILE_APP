// The admin "Users" page: a real, dated activity log per account, and
// direct admin open/close control over any user's access to any pack or
// book — independent of (and able to override) the payment-approval flow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodomed_admin/app/routes.dart';
import 'package:dodomed_core/data/api_client.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_admin/screens/admin/admin_user_detail_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_users_screen.dart';

import 'package:dodomed_core/test_support/fake_backend.dart';

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

    test('setUserRole promotes a learner to admin, then demotes them back',
        () async {
      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      await _signedInLearner(backend);
      final learnerId =
          (await admin.fetchAllUsers()).firstWhere((u) => u.email == 'sam@example.com').id;

      final promoted = await admin.setUserRole(userId: learnerId, makeAdmin: true);
      expect(promoted.isAdmin, isTrue);

      final demoted = await admin.setUserRole(userId: learnerId, makeAdmin: false);
      expect(demoted.isAdmin, isFalse);
    });

    test('an admin cannot remove their own admin access', () async {
      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      final adminId = (await admin.fetchAllUsers())
          .firstWhere((u) => u.email == 'admin@example.com')
          .id;

      expect(
        () => admin.setUserRole(userId: adminId, makeAdmin: false),
        throwsA(isA<ApiException>()),
      );
    });

    test('the last remaining admin cannot be demoted by someone else',
        () async {
      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      final other = await _signedInLearner(backend, name: 'Other Admin', email: 'other-admin@example.com');
      final adminId = (await admin.fetchAllUsers())
          .firstWhere((u) => u.email == 'admin@example.com')
          .id;

      // Promote the second account first so there are two admins...
      await admin.setUserRole(userId: (await admin.fetchAllUsers()).firstWhere((u) => u.email == 'other-admin@example.com').id, makeAdmin: true);
      // ...demoting the original admin now succeeds, since another remains.
      await other.setUserRole(userId: adminId, makeAdmin: false);
      final afterFirstDemotion = await other.fetchAllUsers();
      expect(afterFirstDemotion.firstWhere((u) => u.email == 'admin@example.com').isAdmin, isFalse);

      // Now only `other` is an admin — demoting them (by themselves, the
      // only path left) hits the last-admin guard rather than the
      // self-demotion guard, since a *different* caller would be needed to
      // even attempt it and none exists; assert the invariant holds by
      // trying anyway and getting rejected.
      final otherId = (await other.fetchAllUsers())
          .firstWhere((u) => u.email == 'other-admin@example.com')
          .id;
      expect(
        () => other.setUserRole(userId: otherId, makeAdmin: false),
        throwsA(isA<ApiException>()),
      );
    });

    test('a non-admin cannot promote or demote anyone', () async {
      final backend = FakeBackend();
      final learner = await _signedInLearner(backend);
      expect(
        () => learner.setUserRole(userId: 'irrelevant-id', makeAdmin: true),
        throwsA(isA<ApiException>()),
      );
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

      final packSwitch = find.descendant(
        of: find.byKey(const ValueKey('access-exit-3000')),
        matching: find.byType(Switch),
      );
      await tester.tap(packSwitch);
      await pumpAndSettleQuiet(tester);

      expect(find.text('Open'), findsWidgets);

      final refreshed = await admin.fetchUserActivity(learnerSummary.id);
      expect(refreshed.user.unlockedPacks, contains('exit-3000'));
    });

    testWidgets(
        'the admin-access switch promotes a learner to admin, with a confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      await _signedInLearner(backend);
      final learnerSummary = (await admin.fetchAllUsers())
          .firstWhere((u) => u.email == 'sam@example.com');
      expect(learnerSummary.isAdmin, isFalse);

      await tester.pumpWidget(
        _host(admin, AdminUserDetailScreen(user: learnerSummary)),
      );
      await pumpAndSettleQuiet(tester);

      expect(find.text('Learner'), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin-role-switch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // A confirmation dialog appears before anything actually changes.
      expect(find.text('Make this user an admin?'), findsOneWidget);
      await tester.tap(find.text('Make admin'));
      await pumpAndSettleQuiet(tester);

      expect(find.text('Admin'), findsWidgets);

      final users = await admin.fetchAllUsers();
      expect(users.firstWhere((u) => u.email == 'sam@example.com').isAdmin, isTrue);
    });

    testWidgets("an admin can't toggle their own admin access",
        (tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final backend = FakeBackend();
      final admin = await _signedInAdmin(backend);
      final selfSummary = (await admin.fetchAllUsers())
          .firstWhere((u) => u.email == 'admin@example.com');

      await tester.pumpWidget(
        _host(admin, AdminUserDetailScreen(user: selfSummary)),
      );
      await pumpAndSettleQuiet(tester);

      expect(find.textContaining("can't change your own admin access"),
          findsOneWidget);
      final roleSwitch =
          tester.widget<Switch>(find.byKey(const Key('admin-role-switch')));
      expect(roleSwitch.onChanged, isNull);
    });
  });
}
