import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/screens/about_app_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/about_questions_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/dashboard_screen.dart';
import 'package:dodomed_core/screens/ebook_reader_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/ebook_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/exam_screen.dart';
import 'package:dodomed_core/screens/forgot_password_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/home_screen.dart';
import 'package:dodomed_core/screens/login_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/onboarding_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/profile_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/results_screen.dart';
import 'package:dodomed_core/screens/signup_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/track_select_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/payment_method_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/payment_prompt_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/upload_receipt_screen.dart';

void main() {
  // Use the real Nunito font so text metrics match the running app (the test
  // harness would otherwise substitute the very wide "Ahem" font).
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Nunito');
    for (final w in const [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
    }
    await loader.load();
  });

  final pack = MockData.seedExamPacks().first;
  final book = MockData.seedBooks().first;

  final screens = <String, Widget Function()>{
    'onboarding': () => const OnboardingScreen(),
    'login': () => const LoginScreen(homeRoute: '/track'),
    'signup': () => const SignUpScreen(homeRoute: '/track'),
    'forgot password': () => const ForgotPasswordScreen(),
    'track select': () => const TrackSelectScreen(),
    'home': () => const HomeScreen(),
    'dashboard': () => const DashboardScreen(),
    'e-book list': () => const EBookScreen(),
    'e-book reader': () => EBookReaderScreen(book: book, onUnlock: (_) async {}),
    'profile': () => const ProfileScreen(),
    'about (pack)': () => AboutQuestionsScreen(pack: pack),
    'about app': () => const AboutAppScreen(),
    'exam': () => ExamScreen(pack: pack),
    'results': () => ResultsScreen(
        args: ResultsArgs(pack: pack, correct: 9, answered: 10)),
    'pay prompt': () => PaymentPromptScreen(pack: pack),
    'pay method': () => PaymentMethodScreen(pack: pack),
    'upload receipt': () => UploadReceiptScreen(
        args: UploadReceiptArgs(pack: pack, bank: MockData.seedBanks().first)),
  };

  // (width, height, text-scale) — the smallest phone we support up to a large
  // one, plus a large-text case (clamped the way the app clamps it).
  final viewports = <String, ({Size size, double textScale})>{
    'small 360×720': (size: const Size(360, 720), textScale: 1.0),
    'large 430×900': (size: const Size(430, 900), textScale: 1.0),
    'small + big text': (size: const Size(360, 760), textScale: 1.2),
  };

  for (final vp in viewports.entries) {
    group(vp.key, () {
      for (final s in screens.entries) {
        testWidgets(s.key, (tester) async {
          tester.view.physicalSize = vp.value.size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            AppStateScope(
              state: AppState(),
              child: MaterialApp(
                home: s.value(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(vp.value.textScale),
                  ),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 700));
          expect(tester.takeException(), isNull,
              reason: '${vp.key} / ${s.key}');
        });
      }
    });
  }
}
