import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/screens/ebook_reader_screen.dart';
import 'package:dodomed_core/screens/forgot_password_screen.dart';
import 'package:dodomed_core/screens/login_screen.dart';
import 'package:dodomed_core/screens/signup_screen.dart';
import 'package:dodomed_core/screens/splash_screen.dart';

import '../screens/about_app_screen.dart';
import '../screens/about_questions_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/ebook_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/payment/payment_method_screen.dart';
import '../screens/payment/payment_pending_screen.dart';
import '../screens/payment/payment_prompt_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/payment/upload_receipt_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/qa_screen.dart';
import '../screens/results_screen.dart';
import '../screens/track_select_screen.dart';

/// The User App's route table — every non-admin route from the old
/// single-app `routes.dart`. No `admin`/`admin*` routes exist here at all
/// (see the "ua" branch's admin/user split) — an admin account logging in
/// here is turned away by [LoginScreen]'s role gate below, not routed
/// anywhere admin-shaped.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const track = '/track';
  static const ebook = '/ebook';
  static const ebookReader = '/ebook/reader';
  static const about = '/about';
  static const aboutApp = '/about-app';
  static const qa = '/qa';
  static const exam = '/exam';
  static const results = '/results';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const payPrompt = '/pay/prompt';
  static const payMethod = '/pay/method';
  static const payUpload = '/pay/upload';
  static const payPending = '/pay/pending';
  static const paySuccess = '/pay/success';

  /// This account is an admin — used identically by LoginScreen and
  /// SignUpScreen's role gate.
  static const _deniedMessage =
      'This is an admin account — use the DODOMED Admin app instead.';

  /// Switch between top-level sections (Home / Dashboard / E-Book / Profile)
  /// without stacking them: unwind to the app root, then push once.
  static void goToSection(BuildContext context, String route) {
    final nav = Navigator.of(context);
    if (ModalRoute.of(context)?.settings.name == route) return;
    nav.popUntil((r) => r.isFirst);
    if (route != home) nav.pushNamed(route);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    // Fall back to a seed pack / book so deep links / direct navigation work.
    final pack = args is ExamPack ? args : MockData.seedExamPacks().first;
    final book = args is EBook ? args : MockData.seedBooks().first;

    Widget page;
    switch (settings.name) {
      case splash:
        page = const SplashScreen(loggedInRoute: home, loggedOutRoute: onboarding);
        break;
      case onboarding:
        page = const OnboardingScreen();
        break;
      case login:
        page = const LoginScreen(
          homeRoute: track,
          isAllowed: _isNotAdmin,
          deniedMessage: _deniedMessage,
        );
        break;
      case signup:
        page = const SignUpScreen(
          homeRoute: track,
          isAllowed: _isNotAdmin,
          deniedMessage: _deniedMessage,
        );
        break;
      case forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case home:
        page = const HomeScreen();
        break;
      case track:
        page = const TrackSelectScreen();
        break;
      case ebook:
        page = const EBookScreen();
        break;
      case ebookReader:
        // Needs the builder's own context (not available at this point in
        // the switch) to navigate on unlock, so it returns directly here
        // instead of falling through to the shared MaterialPageRoute below.
        return MaterialPageRoute<dynamic>(
          builder: (context) => EBookReaderScreen(
            book: book,
            onUnlock: (b) async {
              final purchasable = AppStateScope.read(context).purchasableForBook(b);
              await Navigator.of(context)
                  .pushNamed(payMethod, arguments: purchasable);
            },
          ),
          settings: settings,
        );
      case dashboard:
        page = const DashboardScreen();
        break;
      case profile:
        page = const ProfileScreen();
        break;
      case about:
        page = AboutQuestionsScreen(pack: pack);
        break;
      case aboutApp:
        page = const AboutAppScreen();
        break;
      case qa:
        page = const QaScreen();
        break;
      case exam:
        page = ExamScreen(pack: pack);
        break;
      case results:
        page = ResultsScreen(
          args: args is ResultsArgs
              ? args
              : ResultsArgs(pack: pack, correct: 27, answered: 30),
        );
        break;
      case payPrompt:
        page = PaymentPromptScreen(pack: pack);
        break;
      case payMethod:
        page = PaymentMethodScreen(pack: pack);
        break;
      case payUpload:
        page = UploadReceiptScreen(
          args: args is UploadReceiptArgs
              ? args
              : UploadReceiptArgs(pack: pack, bank: MockData.seedBanks().first),
        );
        break;
      case payPending:
        page = PaymentPendingScreen(pack: pack);
        break;
      case paySuccess:
        page = PaymentSuccessScreen(pack: pack);
        break;
      default:
        page = const SplashScreen(loggedInRoute: home, loggedOutRoute: onboarding);
    }

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }

  static bool _isNotAdmin(AppState state) => !state.isAdmin;
}
