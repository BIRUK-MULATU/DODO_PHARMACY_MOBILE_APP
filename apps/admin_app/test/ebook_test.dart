import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_admin/app/routes.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_admin/screens/admin/admin_books_screen.dart';

// AppState book CRUD, the free/full reader states, and
// `purchasableForBook` are all covered in
// apps/user_app/test/ebook_test.dart — this file covers only the
// admin-side "add a book through the form" flow, since AdminBooksScreen
// doesn't exist in the user app.
Widget _host(AppState state, Widget home) => AppStateScope(
      state: state,
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    );

void main() {
  testWidgets('admin adds a book through the form', (tester) async {
    tester.view.physicalSize = const Size(700, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    final before = s.books.length;

    await tester.pumpWidget(_host(s, const AdminBooksScreen()));
    await tester.pump();
    await tester.tap(find.text('New book'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'Lab Science Primer');
    await tester.enterText(find.byType(TextFormField).at(1), '300'); // price
    await tester.enterText(find.byType(TextFormField).at(2), '2'); // free pages
    await tester.enterText(
        find.byType(TextFormField).at(3), 'Hematology, Microbiology');
    await tester.enterText(find.byType(TextFormField).at(4),
        'Intro page.\n---\nSecond page.\n---\nThird page.\n---\nFourth page.');

    await tester.tap(find.text('Add book'));
    await tester.pumpAndSettle();

    expect(s.books.length, before + 1);
    final added = s.books.last;
    expect(added.title, 'Lab Science Primer');
    expect(added.pages.length, 4);
    expect(added.freePages, 2);
    expect(added.subjects, ['Hematology', 'Microbiology']);
  });
}
