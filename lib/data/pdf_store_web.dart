import 'dart:typed_data';

// Web has no file system — the caller keeps the bytes on the model.
Future<String?> savePickedPdf(String bookId, Uint8List bytes) async => null;

Future<void> deleteSavedPdf(String? path) async {}
