import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> savePickedPdf(String bookId, Uint8List bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final books = Directory('${dir.path}/books');
  if (!await books.exists()) {
    await books.create(recursive: true);
  }
  final file = File('${books.path}/$bookId.pdf');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> deleteSavedPdf(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {
    // best effort
  }
}

/// Reads back a PDF previously saved by [savePickedPdf] — used to sync it to
/// the backend, since only the path (not the bytes) is kept on the model
/// once it's on disk. Returns `null` if the file is gone/unreadable.
Future<Uint8List?> readSavedPdf(String? path) async {
  if (path == null || path.isEmpty) return null;
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}
