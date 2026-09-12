// The results screen used to show a fabricated "scaled to the full question
// bank" score (e.g. answering 4/5 in a 3000-question pack showed something
// like "2400 / 3000") instead of what the learner actually did, and only
// ever said "Well done!" regardless of how they scored. These confirm it
// shows the real correct/answered counts and a real accuracy percentage,
// graded into tiers (Needs Improvement / Good / Very Good / Excellent) with
// a message that actually matches the result.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/screens/results_screen.dart';

void main() {
  Future<void> pumpResults(WidgetTester tester, int correct, int answered) async {
    final pack = MockData.seedExamPacks().first; // questionCount: 3000
    await tester.pumpWidget(MaterialApp(
      home: ResultsScreen(
        args: ResultsArgs(pack: pack, correct: correct, answered: answered),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 1600)); // let CountUp settle
  }

  testWidgets('shows the real correct/answered counts, not a scaled score',
      (tester) async {
    await pumpResults(tester, 4, 5);

    // The real numbers.
    expect(find.textContaining('4 / 5 correct'), findsOneWidget);
    expect(find.textContaining('80% accuracy'), findsOneWidget);

    // Not a value fabricated by scaling the sample up to the full pack size
    // (4/5 * 3000 = 2400, the old behaviour).
    expect(find.textContaining('2400'), findsNothing);
    expect(find.textContaining('/ 3000'), findsNothing);
  });

  testWidgets('below 50%: graded "Needs Improvement" and told to improve it',
      (tester) async {
    await pumpResults(tester, 3, 10);

    expect(find.textContaining('3 / 10 correct'), findsOneWidget);
    expect(find.textContaining('30% accuracy'), findsOneWidget);
    expect(find.text('Needs Improvement'), findsOneWidget);
    expect(find.textContaining('improve it'), findsOneWidget);
  });

  testWidgets('50–74%: graded "Good"', (tester) async {
    await pumpResults(tester, 6, 10);

    expect(find.textContaining('60% accuracy'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
  });

  testWidgets('75–89%: graded "Very Good!"', (tester) async {
    await pumpResults(tester, 8, 10);

    expect(find.textContaining('80% accuracy'), findsOneWidget);
    expect(find.text('Very Good!'), findsOneWidget);
  });

  testWidgets('90% and up: graded "Excellent!" and told they deserve it',
      (tester) async {
    await pumpResults(tester, 10, 10);

    expect(find.textContaining('10 / 10 correct'), findsOneWidget);
    expect(find.textContaining('100% accuracy'), findsOneWidget);
    expect(find.text('Excellent!'), findsOneWidget);
    expect(find.textContaining('You deserve it'), findsOneWidget);
  });
}
