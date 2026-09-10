import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/data/models.dart';
import 'package:dodo_pharmacy_mobile_app/screens/admin/admin_payments_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/admin/admin_questions_screen.dart';

Widget _host(AppState state, Widget home) => AppStateScope(
      state: state,
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    );

void main() {
  test('AppState question CRUD', () {
    final s = AppState();
    final before = s.questions.length;

    final q = Question(
      id: s.newQuestionId(),
      packId: 'exit-3000',
      number: 999,
      total: 3000,
      prompt: 'What is the antidote for an acetaminophen overdose?',
      options: ['Naloxone', 'N-acetylcysteine', 'Flumazenil', 'Atropine'],
      correctIndex: 1,
      explanation: 'N-acetylcysteine replenishes glutathione stores.',
    );
    s.addQuestion(q);
    expect(s.questions.length, before + 1);
    expect(s.questions.last.answerLabel, 'B) N-acetylcysteine');

    s.updateQuestion(q.copyWith(correctIndex: 0));
    expect(s.questions.firstWhere((e) => e.id == q.id).answerLabel,
        'A) Naloxone');

    s.deleteQuestion(q.id);
    expect(s.questions.length, before);
  });

  testWidgets('admin approves a payment request and the pack unlocks',
      (tester) async {
    final s = AppState();
    final pack = MockData.examPacks.first;
    s.submitPaymentRequest(pack: pack, bankCode: 'CBE');
    expect(s.pendingPaymentCount, 1);
    expect(s.isUnlocked(pack.id), isFalse);

    await tester.pumpWidget(_host(s, const AdminPaymentsScreen()));
    await tester.pump();

    expect(find.text('Pending'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pump();

    expect(s.isUnlocked(pack.id), isTrue);
    expect(s.pendingPaymentCount, 0);
    expect(find.text('Approved'), findsOneWidget);
  });

  testWidgets('admin questions list shows a delete confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    final count = s.questions.length;
    await tester.pumpWidget(_host(s, const AdminQuestionsScreen()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    expect(find.text('Delete question?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(s.questions.length, count - 1);
  });
}
