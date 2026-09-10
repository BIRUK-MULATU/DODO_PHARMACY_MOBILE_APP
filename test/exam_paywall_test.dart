import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/screens/exam_screen.dart';

void main() {
  testWidgets('exam locks after the free questions and offers a payment button',
      (tester) async {
    final pack = MockData.seedExamPacks().first;
    expect(pack.freeLimit, 5);

    await tester.pumpWidget(
      AppStateScope(
        state: AppState(),
        child: MaterialApp(home: ExamScreen(pack: pack)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Answer the 5 free questions, advancing after each.
    for (var i = 0; i < pack.freeLimit; i++) {
      await tester.tap(find.text('A) ').first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.chevron_right).last);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // The 6th question is now gated.
    expect(find.textContaining('free questions'), findsOneWidget);
    expect(find.textContaining('Go to Payment'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
