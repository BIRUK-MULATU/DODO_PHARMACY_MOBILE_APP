import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('bottom nav switches sections without stacking', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState()..logIn();
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onGenerateInitialRoutes: (_) => [
            AppRoutes.onGenerateRoute(
                const RouteSettings(name: AppRoutes.home)),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(AppBottomNav), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));

    Finder tab(String label) => find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text(label),
        );

    await tester.tap(tab('E-Book'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('premium book collection'), findsOneWidget);

    await tester.tap(tab('Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('Exam Readiness'), findsOneWidget);

    // Back once -> Home (never piled up).
    expect(nav.canPop(), isTrue);
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(nav.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
