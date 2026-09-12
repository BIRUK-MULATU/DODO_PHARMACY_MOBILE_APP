import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/screens/forgot_password_screen.dart';
import 'package:dodomed_core/screens/login_screen.dart';
import 'package:dodomed_core/screens/signup_screen.dart';
import 'package:dodomed_core/screens/splash_screen.dart';

import '../screens/admin/admin_about_screen.dart';
import '../screens/admin/admin_bank_form_screen.dart';
import '../screens/admin/admin_banks_screen.dart';
import '../screens/admin/admin_book_form_screen.dart';
import '../screens/admin/admin_books_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_pack_form_screen.dart';
import '../screens/admin/admin_packs_screen.dart';
import '../screens/admin/admin_payments_screen.dart';
import '../screens/admin/admin_qa_screen.dart';
import '../screens/admin/admin_question_form_screen.dart';
import '../screens/admin/admin_questions_screen.dart';
import '../screens/admin/admin_track_form_screen.dart';
import '../screens/admin/admin_tracks_screen.dart';
import '../screens/admin/admin_user_detail_screen.dart';
import '../screens/admin/admin_users_screen.dart';

/// The Admin App's route table — every route from the old single-app
/// `routes.dart` under `/admin`, plus the shared auth screens. Deliberately
/// has no `home`/`track`/`dashboard`/etc. — those don't exist in this app
/// at all, by design (see the "ua" branch's admin/user split).
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const admin = '/admin';
  static const adminQuestions = '/admin/questions';
  static const adminQuestionForm = '/admin/questions/form';
  static const adminPayments = '/admin/payments';
  static const adminPacks = '/admin/packs';
  static const adminPackForm = '/admin/packs/form';
  static const adminBooks = '/admin/books';
  static const adminBookForm = '/admin/books/form';
  static const adminTracks = '/admin/tracks';
  static const adminTrackForm = '/admin/tracks/form';
  static const adminAbout = '/admin/about';
  static const adminBanks = '/admin/banks';
  static const adminBankForm = '/admin/banks/form';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/detail';
  static const adminQa = '/admin/qa';

  /// This account doesn't hold admin access — used identically by
  /// LoginScreen and SignUpScreen's role gate.
  static const _deniedMessage =
      "This account doesn't have admin access — use the DODOMED app instead.";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    Widget page;
    switch (settings.name) {
      case splash:
        page = const SplashScreen(loggedInRoute: admin, loggedOutRoute: login);
        break;
      case login:
        page = const LoginScreen(
          homeRoute: admin,
          isAllowed: _isAdmin,
          deniedMessage: _deniedMessage,
          hintText: 'Admin accounts only — any other login is turned away.',
        );
        break;
      case signup:
        page = const SignUpScreen(
          homeRoute: admin,
          isAllowed: _isAdmin,
          deniedMessage: _deniedMessage,
        );
        break;
      case forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case admin:
        page = const AdminHomeScreen();
        break;
      case adminQuestions:
        page = const AdminQuestionsScreen();
        break;
      case adminQuestionForm:
        page = AdminQuestionFormScreen(question: args is Question ? args : null);
        break;
      case adminPayments:
        page = const AdminPaymentsScreen();
        break;
      case adminPacks:
        page = const AdminPacksScreen();
        break;
      case adminPackForm:
        page = AdminPackFormScreen(pack: args is ExamPack ? args : null);
        break;
      case adminBooks:
        page = const AdminBooksScreen();
        break;
      case adminBookForm:
        page = AdminBookFormScreen(book: args is EBook ? args : null);
        break;
      case adminTracks:
        page = const AdminTracksScreen();
        break;
      case adminTrackForm:
        page = AdminTrackFormScreen(track: args is Track ? args : null);
        break;
      case adminAbout:
        page = const AdminAboutScreen();
        break;
      case adminBanks:
        page = const AdminBanksScreen();
        break;
      case adminBankForm:
        page = AdminBankFormScreen(bank: args is BankAccount ? args : null);
        break;
      case adminUsers:
        page = const AdminUsersScreen();
        break;
      case adminUserDetail:
        if (args is! AdminUserSummary) {
          page = const AdminUsersScreen();
          break;
        }
        page = AdminUserDetailScreen(user: args);
        break;
      case adminQa:
        page = const AdminQaScreen();
        break;
      default:
        page = const SplashScreen(loggedInRoute: admin, loggedOutRoute: login);
    }

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }

  static bool _isAdmin(AppState state) => state.isAdmin;
}
