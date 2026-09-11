import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/data/models.dart';

import 'support/fake_file_selector.dart';

void main() {
  testWidgets(
      'paying from the paywall, then an admin approval, unlocks the exam',
      (tester) async {
    // A tall viewport so every screen's buttons are on-screen.
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The receipt step now opens the real device picker — fake it so the
    // test picks a receipt image deterministically, no OS dialog needed.
    final previousPicker = installFakeFileSelector();
    addTearDown(() => FileSelectorPlatform.instance = previousPicker);

    // Screens use looping animations, so advance time in fixed steps rather
    // than pumpAndSettle().
    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 750));
    }

    Future<void> tapText(String text) async {
      final finder = find.textContaining(text);
      await tester.ensureVisible(finder.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(finder.first, warnIfMissed: false);
      await settle();
    }

    final state = AppState();
    final pack = MockData.seedExamPacks().first;
    for (var i = 0; i < pack.freeLimit; i++) {
      state.recordAnswer(packId: pack.id, wasCorrect: true);
    }

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onGenerateInitialRoutes: (_) => [
            AppRoutes.onGenerateRoute(
                const RouteSettings(name: AppRoutes.exam)),
          ],
        ),
      ),
    );
    await settle();

    expect(find.textContaining('Go to Payment'), findsOneWidget);

    await tapText('Go to Payment'); // -> pay prompt
    await tapText('Pay Now'); // -> pay method
    await tapText('Proceed to Receipt Upload'); // -> upload receipt

    // Picking a receipt opens the real device image picker (faked above) and
    // decodes it via dart:ui, which needs real async time in a widget test.
    final uploadTile = find.textContaining('Tap to upload receipt');
    await tester.ensureVisible(uploadTile.first);
    await tester.tap(uploadTile.first, warnIfMissed: false);
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle();

    await tapText('Submit Receipt'); // -> pending (awaiting admin review)

    expect(find.textContaining('being reviewed'), findsOneWidget);
    expect(state.pendingPaymentCount, 1);
    expect(state.isUnlocked(pack.id), isFalse);
    // The receipt actually picked from the (fake) device made it onto the
    // payment request the admin will review.
    expect(state.paymentRequests.last.receiptImage, isNotEmpty);

    // Admin approves the receipt from the panel.
    final req = state.paymentRequests.last;
    state.decidePayment(req.id, PaymentStatus.approved);
    await settle();

    // The pending screen reacts and moves on to the success screen.
    expect(state.isUnlocked(pack.id), isTrue);
    expect(find.text('Payment successful'), findsOneWidget);

    await tapText('Nice one!'); // -> back to exam, unlocked

    expect(find.textContaining('Go to Payment'), findsNothing);
    expect(find.textContaining('Question 200'), findsOneWidget);
    expect(find.text('Naproxen'), findsOneWidget); // answer options are back
    expect(tester.takeException(), isNull);
  });
}
