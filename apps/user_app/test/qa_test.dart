// The learner-facing half of the Q&A feature (QaScreen) — asking a
// question and seeing the thread, including an already-answered item
// rendered as a "DODOMED Support" card. The shared AppState-level behavior
// lives in packages/dodomed_core/test/qa_test.dart; the admin half
// (AdminQaScreen) lives in apps/admin_app/test/qa_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/qa_screen.dart';

void main() {
  Widget host(AppState state) => AppStateScope(
        state: state,
        child: const MaterialApp(home: QaScreen()),
      );

  testWidgets('offline: shows the demo thread with a professional answer card',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(AppState()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('DODOMED Support'), findsOneWidget);
    expect(find.textContaining('Access is granted'), findsOneWidget);
  });

  testWidgets('typing a question and tapping Send adds it to the list',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await tester.pumpWidget(host(state));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
        find.byType(TextField), 'Does the price ever change?');
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Does the price ever change?'), findsOneWidget);
    expect(find.textContaining('question was sent'), findsOneWidget);
    expect(state.qaItems.first.question, 'Does the price ever change?');
  });

  testWidgets('an empty question does nothing', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final before = state.qaItems.length;
    await tester.pumpWidget(host(state));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(state.qaItems.length, before);
    expect(tester.takeException(), isNull);
  });
}
