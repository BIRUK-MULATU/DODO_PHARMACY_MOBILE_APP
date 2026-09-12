import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/app/routes.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/screens/ebook_reader_screen.dart';

Widget _host(AppState state, Widget home) => AppStateScope(
      state: state,
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    );

void main() {
  test('AppState book CRUD', () {
    final s = AppState();
    final before = s.books.length;

    final book = EBook(
      id: s.newBookId(),
      title: 'Nursing OSCE Companion',
      priceBirr: 250,
      cover: MockData.bookCovers.first,
      subjects: const ['Fundamentals', 'Med-Surg'],
      pages: const ['Page one text.', 'Page two text.', 'Page three text.'],
      freePages: 1,
    );
    s.addBook(book);
    expect(s.books.length, before + 1);
    expect(s.bookById(book.id)!.pageCount, 3);

    s.updateBook(book.copyWith(priceBirr: 400, freePages: 2));
    expect(s.bookById(book.id)!.priceBirr, 400);
    expect(s.bookById(book.id)!.freePages, 2);

    s.deleteBook(book.id);
    expect(s.books.length, before);
  });

  test('a book with an uploaded PDF reports hasPdf', () {
    final s = AppState();
    final book = EBook(
      id: s.newBookId(),
      title: 'Scanned COC Notes',
      priceBirr: 500,
      cover: MockData.bookCovers.first,
      subjects: const [],
      pdfPath: '/data/user/0/app/books/scanned.pdf',
      pdfName: 'scanned.pdf',
    );
    expect(book.hasPdf, isTrue);
    expect(book.pages, isEmpty);
    s.addBook(book);
    expect(s.bookById(book.id)!.hasPdf, isTrue);
  });

  test('purchasableForBook carries id, title and price into the pay flow', () {
    final s = AppState();
    final book = s.books.first;
    final p = s.purchasableForBook(book);
    expect(p.id, book.id);
    expect(p.title, book.title);
    expect(p.priceBirr, book.priceBirr);
  });

  testWidgets('reader shows only the free pages, then unlocks in full',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    final book = s.books.first; // freePages 4, 8 pages
    await tester.pumpWidget(
        _host(s, EBookReaderScreen(book: book, onUnlock: (_) async {})));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('Preview · 4 of ${book.pageCount} pages'),
        findsOneWidget);
    expect(find.text('Page 4'), findsOneWidget);
    expect(find.text('Page 5'), findsNothing);
    expect(find.textContaining('free pages'), findsOneWidget);
    expect(find.textContaining('Unlock for'), findsOneWidget);

    // Admin approves the payment → book unlocks.
    s.unlock(book.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Page 5'), findsOneWidget); // previously locked
    expect(find.textContaining('Full access'), findsOneWidget);
    expect(find.textContaining('Unlock for'), findsNothing);

    // The previously-locked pages and the end marker are reachable by scrolling.
    await tester.scrollUntilVisible(
      find.text('— End of book —'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Page ${book.pageCount}'), findsOneWidget);
    expect(find.text('— End of book —'), findsOneWidget);
  });

  // "admin adds a book through the form" lives in
  // apps/admin_app/test/ebook_test.dart — AdminBooksScreen doesn't exist in
  // this app.
}
