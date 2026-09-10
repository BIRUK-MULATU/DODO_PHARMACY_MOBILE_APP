import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/widgets/app_drawer.dart';

void main() {
  testWidgets('drawer opens, lists the sections and switches without stacking',
      (tester) async {
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

    final nav = tester.state<NavigatorState>(find.byType(Navigator));

    // Open the drawer.
    await tester.tap(find.byIcon(Icons.menu).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));

    Finder inDrawer(String text) => find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text(text),
        );
    expect(inDrawer('Profile'), findsOneWidget);
    expect(inDrawer('Dashboard'), findsOneWidget);
    expect(inDrawer('E-Book'), findsOneWidget);
    expect(inDrawer('About'), findsOneWidget);
    expect(inDrawer('Log Out'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "About" opens the app-info page.
    await tester.tap(inDrawer('About'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('DODOMED'), findsOneWidget);
    expect(find.textContaining('study companion'), findsOneWidget);
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Re-open the drawer for the next step.
    await tester.tap(find.byIcon(Icons.menu).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));

    // Tap through to Dashboard.
    await tester.tap(inDrawer('Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('Exam Readiness'), findsOneWidget);

    // Exactly one route sits above Home, so a single back returns there.
    expect(nav.canPop(), isTrue);
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(nav.canPop(), isFalse);
    expect(find.textContaining('2027 Huge discount'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
