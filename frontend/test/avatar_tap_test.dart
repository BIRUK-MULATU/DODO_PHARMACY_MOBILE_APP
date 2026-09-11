import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/widgets/wave.dart';

void main() {
  testWidgets('tapping the header avatar opens Profile without stacking',
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

    // The avatar is the last tappable in the WaveHeader (after the menu button).
    final avatar = find.descendant(
      of: find.byType(WaveHeader),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(avatar.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('My Profile'), findsOneWidget);

    // Only one route above Home.
    expect(nav.canPop(), isTrue);
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(nav.canPop(), isFalse);
    expect(find.textContaining('2027 Huge discount'), findsOneWidget);
  });
}
