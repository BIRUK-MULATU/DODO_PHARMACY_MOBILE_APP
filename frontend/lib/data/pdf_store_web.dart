import 'dart:typed_data';

// Web has no file system — the caller keeps the bytes on the model.
Future<String?> savePickedPdf(String bookId, Uint8List bytes) async => null;

Future<void> deleteSavedPdf(String? path) async {}

// Web never has a saved path — the model already holds the bytes directly.
Future<Uint8List?> readSavedPdf(String? path) async => null;
