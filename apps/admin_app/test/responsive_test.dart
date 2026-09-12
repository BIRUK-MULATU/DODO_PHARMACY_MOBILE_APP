// Overflow sweep for every admin screen, at the same viewports/text-scales
// as the user app's own responsive_test.dart. The non-admin screens live
// in apps/user_app/test/responsive_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_admin/screens/admin/admin_about_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_banks_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_books_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_home_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_packs_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_payments_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_questions_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_tracks_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_users_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_qa_screen.dart';

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

  final screens = <String, Widget Function()>{
    'admin home': () => const AdminHomeScreen(),
    'admin about': () => const AdminAboutScreen(),
    'admin books': () => const AdminBooksScreen(),
    'admin packs': () => const AdminPacksScreen(),
    'admin tracks': () => const AdminTracksScreen(),
    'admin payments': () => const AdminPaymentsScreen(),
    'admin questions': () => const AdminQuestionsScreen(),
    'admin banks': () => const AdminBanksScreen(),
    'admin users': () => const AdminUsersScreen(),
    'admin qa': () => const AdminQaScreen(),
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
