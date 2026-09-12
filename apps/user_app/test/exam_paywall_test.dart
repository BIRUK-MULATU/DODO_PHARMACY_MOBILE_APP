import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/screens/exam_screen.dart';

void main() {
  test('questionLocked gates by index even with nothing answered', () {
    final s = AppState();
    final pack = MockData.seedExamPacks().first; // freeLimit 5

    expect(s.questionLocked(pack, 0), isFalse);
    expect(s.questionLocked(pack, 4), isFalse);
    expect(s.questionLocked(pack, 5), isTrue); // 6th question — past the window
    expect(s.questionLocked(pack, 42), isTrue);
    expect(s.maxReachableIndex(pack), 5);

    s.unlock(pack.id);
    expect(s.questionLocked(pack, 42), isFalse);
    expect(s.maxReachableIndex(pack), pack.questionCount - 1);
  });

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

  testWidgets('skipping ahead with Next (no answers) still hits the paywall',
      (tester) async {
    final pack = MockData.seedExamPacks().first;

    await tester.pumpWidget(
      AppStateScope(
        state: AppState(),
        child: MaterialApp(home: ExamScreen(pack: pack)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // First question is free and shows its options.
    expect(find.text('Locked'), findsNothing);
    expect(find.text('A) ').hitTestable(), findsOneWidget);

    // Hammer "Next" without answering anything.
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right).last);
      await tester.pump(const Duration(milliseconds: 250));
    }

    // Can't get past the free window: still on question 6, and it's locked
    // with no options / prompt visible.
    expect(find.text('Question 6 of ${pack.questionCount}'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.textContaining('Go to Payment'), findsOneWidget);
    expect(find.text('A) '), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
