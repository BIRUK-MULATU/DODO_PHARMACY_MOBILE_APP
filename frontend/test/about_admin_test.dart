import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/about_app_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/admin/admin_about_screen.dart';

Widget _host(AppState state, Widget home) => AppStateScope(
      state: state,
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    );

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

    await tester.pumpWidget(_host(s, const AboutAppScreen()));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('A brand new intro line.'), findsOneWidget);
    expect(find.text('How unlocking works'), findsNothing);
    expect(find.text('What you get'), findsOneWidget);
  });

  testWidgets('admin edits the About page through the form', (tester) async {
    tester.view.physicalSize = const Size(700, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    await tester.pumpWidget(_host(s, const AdminAboutScreen()));
    await tester.pump();

    // version is the first field, intro the second.
    await tester.enterText(find.byType(TextField).at(0), '3.0');
    await tester.enterText(
        find.byType(TextField).at(1), 'Rewritten by the admin.');
    // features field is the third; one bullet per line.
    await tester.enterText(
        find.byType(TextField).at(2), 'First perk\nSecond perk\n');

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(s.aboutInfo.version, '3.0');
    expect(s.aboutInfo.intro, 'Rewritten by the admin.');
    expect(s.aboutInfo.features, ['First perk', 'Second perk']);
  });
}
