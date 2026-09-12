import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/widgets/app_image.dart';

// A 1x1 transparent PNG.
const _px1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
final _dataUri = 'data:image/png;base64,$_px1';

void main() {
  test('AppImage.isUploaded distinguishes uploads from bundled assets', () {
    expect(AppImage.isUploaded(_dataUri), isTrue);
    expect(AppImage.isUploaded('assets/images/book_cover.png'), isFalse);
    expect(AppImage.isUploaded(''), isFalse);
  });

  testWidgets('AppImage renders bundled assets and uploaded data URIs',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Column(children: [
        AppImage(_dataUri, width: 20, height: 20),
        const AppImage('assets/images/book_cover.png', width: 20, height: 20),
      ]),
    ));
    await tester.pump();

    expect(find.byType(Image), findsNWidgets(2));
    // The uploaded one decodes to bytes and uses Image.memory.
    final memory = tester
        .widgetList<Image>(find.byType(Image))
        .where((i) => i.image is MemoryImage);
    expect(memory, isNotEmpty);
    expect(base64Decode(_px1).isNotEmpty, isTrue);
  });

  test('an uploaded image string round-trips through pack / track / book CRUD',
      () {
    final s = AppState();

    final pack = ExamPack(
      id: s.newPackId(),
      trackId: 'pharmacy',
      title: 'Uploaded-cover pack',
      image: _dataUri,
      questionCount: 100,
      priceBirr: 100,
      freeLimit: 3,
    );
    s.addPack(pack);
    expect(s.packById(pack.id)!.image, _dataUri);

    final track = Track(id: s.newTrackId(), name: 'Custom', figure: _dataUri);
    s.addTrack(track);
    expect(s.trackById(track.id)!.figure, _dataUri);

    final book = EBook(
      id: s.newBookId(),
      title: 'Uploaded-cover book',
      priceBirr: 200,
      cover: _dataUri,
      subjects: const [],
      pages: const ['one'],
    );
    s.addBook(book);
    expect(s.bookById(book.id)!.cover, _dataUri);

    // sanity: seed content still uses bundled assets
    expect(MockData.packImages.first.startsWith('assets/'), isTrue);
  });
}
