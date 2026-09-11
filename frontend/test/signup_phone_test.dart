import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/signup_screen.dart';

import 'support/fake_backend.dart';

void main() {
  testWidgets('sign-up captures the phone number into the profile',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState()..apiClientFactory = FakeBackend().client;
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const SignUpScreen(),
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Phone number'), findsOneWidget);

    final passwordFields = find.widgetWithText(TextField, 'Password');
    await tester.enterText(
        find.widgetWithText(TextField, 'Full name'), 'Sam Learner');
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'sam@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Phone number'), '+251900112233');
    await tester.enterText(passwordFields.at(0), 'secret123');
    await tester.enterText(passwordFields.at(1), 'secret123');
    await tester.tap(find.text('Sign Up'));
    // The sign-up call and the catalog fetch it triggers both go through a
    // fake in-memory backend (no real network/timers), but still need a few
    // pumps to drain their Future chains.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(state.profile.phone, '+251900112233');
    expect(state.profile.email, 'sam@example.com');
    expect(state.loggedIn, isTrue);
    // The real bug this used to have: every signup registered with the
    // app's leftover default demo identity ("Aster Ali"/"Asterali") instead
    // of anything the actual new user typed, since the form never asked
    // for a name at all.
    expect(state.profile.name, 'Sam Learner');
    expect(state.profile.username, 'sam');
  });

  testWidgets('sign-up is rejected without a name', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState()..apiClientFactory = FakeBackend().client;
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const SignUpScreen(),
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    final passwordFields = find.widgetWithText(TextField, 'Password');
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'noname@example.com');
    await tester.enterText(passwordFields.at(0), 'secret123');
    await tester.enterText(passwordFields.at(1), 'secret123');
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.textContaining('Enter your name'), findsOneWidget);
    expect(state.loggedIn, isFalse);
  });
}
