import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/widgets/screenshot_guard.dart';

void main() {
  testWidgets('ScreenshotGuard renders its child and stays out of the way',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ScreenshotGuard(
        navigatorKey: navKey,
        child: MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('protected content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('protected content'), findsOneWidget);
    // The plugin channel is unavailable in tests; the guard must swallow that
    // and never throw or block the tree.
    expect(tester.takeException(), isNull);
  });
}
