import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/data/mock_data.dart';
import 'package:dodo_pharmacy_mobile_app/screens/admin/admin_payments_screen.dart';
import 'package:dodo_pharmacy_mobile_app/screens/payment/upload_receipt_screen.dart';
import 'package:dodo_pharmacy_mobile_app/widgets/app_image.dart';

import 'support/fake_file_selector.dart';

void main() {
  test('submitPaymentRequest stores the picked receipt image', () {
    final s = AppState();
    final pack = MockData.seedExamPacks().first;

    final req = s.submitPaymentRequest(
      pack: pack,
      bankCode: 'CBE',
      receiptImage: 'data:image/png;base64,abc123',
    );

    expect(req.receiptImage, 'data:image/png;base64,abc123');
    expect(s.paymentRequests.single.receiptImage, isNotEmpty);
  });

  test('submitPaymentRequest defaults to no receipt image', () {
    final s = AppState();
    final pack = MockData.seedExamPacks().first;
    final req = s.submitPaymentRequest(pack: pack, bankCode: 'CBE');
    expect(req.receiptImage, isEmpty);
  });

  testWidgets(
      'picking a receipt from the device attaches it and enables Submit',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final previous = installFakeFileSelector();
    addTearDown(() => FileSelectorPlatform.instance = previous);

    final pack = MockData.seedExamPacks().first;
    final state = AppState();
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: UploadReceiptScreen(
            args: UploadReceiptArgs(pack: pack, bank: MockData.banks.first),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Submit is disabled before a receipt is picked.
    expect(find.text('Tap to upload receipt'), findsOneWidget);
    expect(find.textContaining('Receipt attached'), findsNothing);

    final tile = find.textContaining('Tap to upload receipt');
    await tester.tap(tile.first, warnIfMissed: false);
    await tester.pump();
    // Image decoding runs on the engine's real thread pool — needs runAsync.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Receipt attached'), findsOneWidget);

    await tester.tap(find.text('Submit Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(state.pendingPaymentCount, 1);
    expect(state.paymentRequests.single.receiptImage, isNotEmpty);
  });

  testWidgets('admin sees the uploaded receipt photo, not a placeholder',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final pack = MockData.seedExamPacks().first;
    state.submitPaymentRequest(
      pack: pack,
      bankCode: 'CBE',
      receiptImage:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAf'
          'FcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: AdminPaymentsScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('No receipt attached'), findsNothing);
    expect(find.byType(AppImage), findsWidgets);
  });
}
