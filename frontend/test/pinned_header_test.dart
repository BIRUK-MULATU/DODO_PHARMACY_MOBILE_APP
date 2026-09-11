import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/dashboard_screen.dart';
import 'package:dodo_pharmacy_mobile_app/widgets/wave.dart';

void main() {
  testWidgets('the top nav header stays pinned while the page scrolls',
      (tester) async {
    tester.view.physicalSize = const Size(400, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: AppState(),
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    final headerTitle = find.descendant(
      of: find.byType(WaveHeader),
      matching: find.text('Dashboard'),
    );

    // Header on screen, bottom content not yet.
    expect(headerTitle, findsOneWidget);
    expect(find.text('Recent Activity'), findsNothing);
    final headerTop = tester.getTopLeft(find.byType(WaveHeader)).dy;

    // Scroll the page up.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Header did not move; lower content is now reachable.
    expect(headerTitle, findsOneWidget);
    expect(tester.getTopLeft(find.byType(WaveHeader)).dy,
        moreOrLessEquals(headerTop, epsilon: 1));
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
