import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/screens/about_questions_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/dashboard_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/ebook_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/exam_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/home_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/login_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/onboarding_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/profile_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/results_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/signup_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/track_select_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/payment_method_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/payment_pending_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/payment_prompt_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/payment_success_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/upload_receipt_screen.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    AppStateScope(
      state: AppState(),
      child: MaterialApp(home: screen),
    ),
  );
  // Let entrance animations and one repeating-animation frame run.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 700));
  expect(tester.takeException(), isNull);
}

void main() {
  final pack = MockData.examPacks.first;

  testWidgets('onboarding', (t) => _pump(t, const OnboardingScreen()));
  testWidgets('login', (t) => _pump(t, const LoginScreen()));
  testWidgets('signup', (t) => _pump(t, const SignUpScreen()));
  testWidgets('track', (t) => _pump(t, const TrackSelectScreen()));
  testWidgets('home', (t) => _pump(t, const HomeScreen()));
  testWidgets('ebook', (t) => _pump(t, const EBookScreen()));
  testWidgets('dashboard', (t) => _pump(t, const DashboardScreen()));
  testWidgets('profile', (t) => _pump(t, const ProfileScreen()));
  testWidgets('about', (t) => _pump(t, AboutQuestionsScreen(pack: pack)));
  testWidgets('exam', (t) => _pump(t, ExamScreen(pack: pack)));
  testWidgets('results', (t) async {
    await _pump(
        t, ResultsScreen(args: ResultsArgs(pack: pack, correct: 9, answered: 10)));
  });
  testWidgets('pay prompt', (t) => _pump(t, PaymentPromptScreen(pack: pack)));
  testWidgets('pay method', (t) => _pump(t, PaymentMethodScreen(pack: pack)));
  testWidgets('upload receipt', (t) async {
    await _pump(
      t,
      UploadReceiptScreen(
        args: UploadReceiptArgs(pack: pack, bank: MockData.banks.first),
      ),
    );
  });
  testWidgets('pay pending', (tester) async {
    await tester.pumpWidget(
      AppStateScope(
        state: AppState(),
        child: MaterialApp(
          home: PaymentPendingScreen(pack: pack),
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('being reviewed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('pay success', (t) => _pump(t, PaymentSuccessScreen(pack: pack)));
}
