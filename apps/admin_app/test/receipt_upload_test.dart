import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodomed_admin/screens/admin/admin_payments_screen.dart';
import 'package:dodomed_core/widgets/app_image.dart';

// The learner-side receipt-picking flow (submitPaymentRequest, the real
// device picker) lives in apps/user_app/test/receipt_upload_test.dart —
// this file covers only the admin-side "sees the real photo" check, since
// AdminPaymentsScreen doesn't exist in the user app.
void main() {
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
