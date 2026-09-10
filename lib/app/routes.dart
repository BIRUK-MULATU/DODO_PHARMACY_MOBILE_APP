import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../screens/about_questions_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/ebook_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/payment/payment_method_screen.dart';
import '../screens/payment/payment_pending_screen.dart';
import '../screens/payment/payment_prompt_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/payment/upload_receipt_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_packs_screen.dart';
import '../screens/admin/admin_payments_screen.dart';
import '../screens/admin/admin_question_form_screen.dart';
import '../screens/admin/admin_questions_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/results_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/track_select_screen.dart';

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
  static const about = '/about';
  static const exam = '/exam';
  static const results = '/results';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const payPrompt = '/pay/prompt';
  static const payMethod = '/pay/method';
  static const payUpload = '/pay/upload';
  static const payPending = '/pay/pending';
  static const paySuccess = '/pay/success';
  static const admin = '/admin';
  static const adminQuestions = '/admin/questions';
  static const adminQuestionForm = '/admin/questions/form';
  static const adminPayments = '/admin/payments';
  static const adminPacks = '/admin/packs';

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
    // Fall back to the primary pack so deep links / direct navigation work.
    final pack = args is ExamPack ? args : MockData.examPacks.first;

    Widget page;
    switch (settings.name) {
      case splash:
        page = const SplashScreen();
        break;
      case onboarding:
        page = const OnboardingScreen();
        break;
      case login:
        page = const LoginScreen();
        break;
      case signup:
        page = const SignUpScreen();
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
      case dashboard:
        page = const DashboardScreen();
        break;
      case profile:
        page = const ProfileScreen();
        break;
      case about:
        page = AboutQuestionsScreen(pack: pack);
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
              : UploadReceiptArgs(pack: pack, bank: MockData.banks.first),
        );
        break;
      case payPending:
        page = PaymentPendingScreen(pack: pack);
        break;
      case paySuccess:
        page = PaymentSuccessScreen(pack: pack);
        break;
      case admin:
        page = const AdminHomeScreen();
        break;
      case adminQuestions:
        page = const AdminQuestionsScreen();
        break;
      case adminQuestionForm:
        page = AdminQuestionFormScreen(
            question: args is Question ? args : null);
        break;
      case adminPayments:
        page = const AdminPaymentsScreen();
        break;
      case adminPacks:
        page = const AdminPacksScreen();
        break;
      default:
        page = const SplashScreen();
    }

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}
