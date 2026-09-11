import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/api_client.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/forgot_password_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/login_screen.dart';

import 'support/fake_backend.dart';

void main() {
  testWidgets(
      'forgot-password: send code then reset updates the account on the backend',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final email = 'sam@example.com';
    final backend = FakeBackend()
      ..users[email] = {
        'id': 'u1',
        'name': 'Sam',
        'username': 'sam',
        'email': email,
        'password': 'oldpass',
        'phone': '',
        'role': 'user',
        'avatar': 'assets/images/avatar.png',
        'unlockedPacks': <String>[],
        'uploadAttempts': 0,
        'progress': <String, dynamic>{},
        'token': 'tok-$email',
      };

    final state = AppState()..apiClientFactory = backend.client;
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const ForgotPasswordScreen(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Phase 1
    expect(find.text('Reset password'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.tap(find.text('Send reset code'));
    await tester.pump(const Duration(milliseconds: 400));

    // Phase 2
    expect(find.text('New password'), findsWidgets);
    await tester.enterText(
        find.widgetWithText(TextField, 'Reset code'), '1234');
    final pwFields = find.widgetWithText(TextField, 'New password');
    await tester.enterText(pwFields.at(0), 'newpass');
    await tester.enterText(pwFields.at(1), 'newpass');
    await tester.tap(find.text('Reset password'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // The real account on the backend changed, not just some local guess.
    expect(backend.users[email]!['password'], 'newpass');
    // Landed on the login screen.
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('wrong code shows an error and does not reset', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // No backend needed — an incorrect code is rejected client-side before
    // any network call.
    final state = AppState();
    final original = state.profile.password;
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const ForgotPasswordScreen(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), state.profile.email);
    await tester.tap(find.text('Send reset code'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(
        find.widgetWithText(TextField, 'Reset code'), '0000');
    await tester.tap(find.text('Reset password'));
    await tester.pump();

    expect(find.textContaining('Incorrect code'), findsOneWidget);
    expect(state.profile.password, original);
  });

  testWidgets(
      'when no backend is reachable, falls back to updating the locally-loaded demo profile',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState()
      ..apiClientFactory = () => ApiClient(
          client: MockClient((_) async => throw Exception('Connection refused')));

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const ForgotPasswordScreen(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), state.profile.email);
    await tester.tap(find.text('Send reset code'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(
        find.widgetWithText(TextField, 'Reset code'), '1234');
    final pwFields = find.widgetWithText(TextField, 'New password');
    await tester.enterText(pwFields.at(0), 'newpass');
    await tester.enterText(pwFields.at(1), 'newpass');
    await tester.tap(find.text('Reset password'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(state.profile.password, 'newpass');
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
