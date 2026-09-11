// Exercises the dashboard's real (not hardcoded) visualizations end to end
// through the actual screen: Best Streak, Rank/Leaderboard, This Week, Pack
// Progress, and Recent Activity all against a fake backend.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/dashboard_screen.dart';

import 'support/fake_backend.dart';

void main() {
  Future<void> pumpDashboard(WidgetTester tester, AppState state) async {
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Reveal the stat row's later cards (Best Streak, Rank) — it's its own
    // horizontal scroller, separate from the page's vertical one.
    await tester.drag(find.byType(ListView), const Offset(-400, 0));
    await tester.pump(const Duration(milliseconds: 300));
    // Scroll the page itself down so the lower panels (Leaderboard, Pack
    // Progress, Recent Activity) actually get built — a CustomScrollView
    // only materializes what's within its viewport + cache extent.
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('offline: dashboard renders with no exceptions, Rank shows 1',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDashboard(tester, AppState());

    expect(tester.takeException(), isNull);
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Pack Progress'), findsOneWidget);
    expect(find.textContaining('only learner'), findsOneWidget);
  });

  testWidgets(
      'online: Best Streak, Rank and Recent Activity reflect real answers',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final backend = FakeBackend()
      ..packs.add({
        'id': 'exit-3000',
        'trackId': 'pharmacy',
        'title': 'Exit exam',
        'image': '',
        'questionCount': 100,
        'priceBirr': 500,
        'freeLimit': 5,
      });
    final state = AppState()..apiClientFactory = backend.client;
    await state.authSignUp(
      name: 'Sam',
      username: 'sam',
      email: 'sam@example.com',
      password: 'secret123',
      phone: '',
    );

    // Answer two questions before the dashboard even opens, so its initial
    // fetch already has real history to show.
    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    state.recordAnswer(packId: 'exit-3000', wasCorrect: true);
    expect(state.bestStreak, 2);

    await pumpDashboard(tester, state);

    expect(tester.takeException(), isNull);
    // Best Streak stat card now shows the real streak (2), not
    // totalCorrect-mislabeled-as-streak and not a hardcoded value.
    expect(find.text('2'), findsWidgets);
    // Only one real learner exists — rank #1.
    expect(find.text('#1'), findsOneWidget);
    expect(find.textContaining('only learner'), findsOneWidget);
    // Recent Activity shows the real pack title, not a fake subject name.
    expect(find.text('Exit exam'), findsWidgets);
    expect(find.text('Pharmacology'), findsNothing);
  });
}
