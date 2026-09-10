import 'dart:typed_data';

import 'pdf_store_io.dart' if (dart.library.js_interop) 'pdf_store_web.dart'
    as impl;

/// Persists a PDF the admin picked from their device.
///
/// On mobile / desktop the bytes are written into the app documents directory
/// and the returned path points at the saved file. On web there is no file
/// system, so this returns `null` and the caller keeps the raw bytes on the
/// model instead.
Future<String?> savePickedPdf(String bookId, Uint8List bytes) =>
    impl.savePickedPdf(bookId, bytes);

/// Best-effort removal of a previously saved PDF. No-op on web.
Future<void> deleteSavedPdf(String? path) => impl.deleteSavedPdf(path);
