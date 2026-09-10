import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/widgets/swipe_to_start.dart';

Widget _host(VoidCallback onComplete) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SwipeToStart(onComplete: onComplete),
          ),
        ),
      ),
    );

void main() {
  testWidgets('a partial swipe springs back and does not complete',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(_host(() => completed = true));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.drag(find.byType(SwipeToStart), const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 600));

    expect(completed, isFalse);
  });

  testWidgets('a full swipe fires onComplete', (tester) async {
    var completed = false;
    await tester.pumpWidget(_host(() => completed = true));
    await tester.pump(const Duration(milliseconds: 200));

    final start = tester.getCenter(find.byType(SwipeToStart));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(700, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(completed, isTrue);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
