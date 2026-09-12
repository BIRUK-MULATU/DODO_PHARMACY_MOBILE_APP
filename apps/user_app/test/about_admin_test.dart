import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/about_app_screen.dart';

void main() {
  test('updateAboutInfo round-trips and copyWith keeps the rest', () {
    final s = AppState();
    expect(s.aboutInfo.version, '1.0.0');

    s.updateAboutInfo(s.aboutInfo.copyWith(
      version: '2.4',
      supportPhone: '',
      features: ['Only this one'],
    ));

    expect(s.aboutInfo.version, '2.4');
    expect(s.aboutInfo.supportPhone, '');
    expect(s.aboutInfo.features, ['Only this one']);
    // untouched fields survived
    expect(s.aboutInfo.supportEmail, 'support@dodomed.et');
    expect(s.aboutInfo.intro, contains('study companion'));
  });

  testWidgets('About screen reflects edits and hides emptied sections',
      (tester) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    s.updateAboutInfo(s.aboutInfo.copyWith(
      intro: 'A brand new intro line.',
      unlocking: '', // hide the section
    ));

    await tester.pumpWidget(AppStateScope(
      state: s,
      child: const MaterialApp(home: AboutAppScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('A brand new intro line.'), findsOneWidget);
    expect(find.text('How unlocking works'), findsNothing);
    expect(find.text('What you get'), findsOneWidget);
  });

  // The admin-side "edit the About page through the form" test lives in
  // apps/admin_app/test/about_admin_test.dart — AdminAboutScreen doesn't
  // exist in this app.
}
