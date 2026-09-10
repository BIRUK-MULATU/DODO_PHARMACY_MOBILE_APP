import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/profile_screen.dart';

void main() {
  testWidgets('user edits their profile on-device and it saves', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Fields start read-only.
    expect(find.text('Edit Profile'), findsOneWidget);

    await tester.tap(find.text('Edit Profile'));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'Aster B. Ali');
    await tester.enterText(
        find.widgetWithText(TextField, 'Phone number'), '+251911000000');

    await tester.tap(find.text('Save Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(state.profile.name, 'Aster B. Ali');
    expect(state.profile.phone, '+251911000000');
    // Back to read-only view, header reflects the new name.
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Aster B. Ali'), findsWidgets);
  });

  testWidgets('an invalid email is rejected', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final original = state.profile.email;
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('Edit Profile'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'not-an-email');
    await tester.tap(find.text('Save Profile'));
    await tester.pump();

    expect(find.textContaining('valid email'), findsOneWidget);
    expect(state.profile.email, original);
  });

  test('AppState.setAvatar updates the profile picture', () {
    final state = AppState();
    expect(state.profile.avatar, 'assets/images/avatar.png');
    state.setAvatar('assets/images/pharmacist.png');
    expect(state.profile.avatar, 'assets/images/pharmacist.png');
  });
}
