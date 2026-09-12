import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_admin/screens/admin/admin_about_screen.dart';

// The AppState-level round-trip test and the AboutAppScreen (user-facing)
// rendering test live in apps/user_app/test/about_admin_test.dart —
// AboutAppScreen doesn't exist in this app.
void main() {
  testWidgets('admin edits the About page through the form', (tester) async {
    tester.view.physicalSize = const Size(700, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    await tester.pumpWidget(AppStateScope(
      state: s,
      child: const MaterialApp(home: AdminAboutScreen()),
    ));
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
