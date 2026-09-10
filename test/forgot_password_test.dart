import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/forgot_password_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/login_screen.dart';

void main() {
  testWidgets('forgot-password: send code then reset updates the password',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
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
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), state.profile.email);
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.profile.password, 'newpass');
    // Landed on the login screen.
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('wrong code shows an error and does not reset', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
}
