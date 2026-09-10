import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/signup_screen.dart';

void main() {
  testWidgets('sign-up captures the phone number into the profile',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
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

    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'sam@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Phone number'), '+251900112233');
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(state.profile.phone, '+251900112233');
    expect(state.profile.email, 'sam@example.com');
    expect(state.loggedIn, isTrue);
  });
}
