// Confirms that content admin edits actually shows up where the user sees
// it — the promo strip, the onboarding subtitle, the "About Questions"
// bullets, and the bank accounts on the payment-method screen. All four used
// to be hardcoded with no admin control at all.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/data/models.dart';
import 'package:dodo_pharmacy_mobile_app/screens/about_questions_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/home_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/onboarding_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/payment_method_screen.dart';

Widget _host(AppState state, Widget home) => AppStateScope(
      state: state,
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    );

void main() {
  testWidgets('an admin-edited promo strip shows up on Home',
      (tester) async {
    final s = AppState();
    s.updateAboutInfo(s.aboutInfo.copyWith(marqueeText: 'Custom promo copy'));

    await tester.pumpWidget(_host(s, const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Custom promo copy'), findsWidgets);
    expect(find.textContaining('What We Offer - 2027'), findsNothing);
  });

  testWidgets('an admin-edited onboarding subtitle shows up on first launch',
      (tester) async {
    final s = AppState();
    s.updateAboutInfo(
        s.aboutInfo.copyWith(onboardingSubtitle: 'Custom welcome message'));

    await tester.pumpWidget(_host(s, const OnboardingScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Custom welcome message'), findsOneWidget);
  });

  testWidgets(
      'admin-edited "About Questions" bullets show up on that pack\'s own screen',
      (tester) async {
    final s = AppState();
    // Each pack has its own About Questions content — editing one pack must
    // not affect another's.
    final packA = s.examPacks[0].copyWith(
      aboutSummary: 'Custom summary for pack A',
      aboutBullets: ['A totally custom bullet point'],
      coreCourses: ['A totally custom course'],
    );
    s.updatePack(packA);
    final packB = s.examPacks[1];

    await tester.pumpWidget(_host(s, AboutQuestionsScreen(pack: packA)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Custom summary for pack A'), findsOneWidget);
    expect(find.text('A totally custom bullet point'), findsOneWidget);
    expect(find.text('A totally custom course'), findsOneWidget);

    await tester.pumpWidget(_host(s, AboutQuestionsScreen(pack: packB)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('A totally custom bullet point'), findsNothing);
  });

  testWidgets(
      'an admin-added bank account shows up on the payment-method screen',
      (tester) async {
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    s.addBank(BankAccount(
      code: 'TEST',
      name: 'Test Bank',
      owner: 'Someone',
      number: '424242',
    ));
    final pack = MockData.seedExamPacks().first;

    await tester.pumpWidget(_host(s, PaymentMethodScreen(pack: pack)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TEST'), findsOneWidget);
  });

  testWidgets('deleting every bank account disables checkout instead of '
      'crashing', (tester) async {
    final s = AppState();
    for (final b in List.of(s.banks)) {
      s.deleteBank(b.code);
    }
    final pack = MockData.seedExamPacks().first;

    await tester.pumpWidget(_host(s, PaymentMethodScreen(pack: pack)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('No bank accounts'), findsOneWidget);
  });
}
