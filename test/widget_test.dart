import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/app.dart';

void main() {
  testWidgets('App boots to the splash screen', (tester) async {
    await tester.pumpWidget(const DodoPharmacyApp());
    await tester.pump();

    // The animated wordmark on the splash screen.
    expect(find.text('DODOMED'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
