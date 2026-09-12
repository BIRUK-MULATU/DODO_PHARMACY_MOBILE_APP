import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

/// A 1x1 transparent PNG — enough for `pickImageAsDataUri` to decode.
final Uint8List fake1x1Png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9'
  'awAAAABJRU5ErkJggg==',
);

/// A [FileSelectorPlatform] that "picks" [bytes] without showing a real file
/// dialog, so widget tests can exercise device-picker flows deterministically.
class FakeFileSelector extends FileSelectorPlatform {
  FakeFileSelector([Uint8List? bytes]) : bytes = bytes ?? fake1x1Png;
  final Uint8List bytes;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    return XFile.fromData(bytes, mimeType: 'image/png', path: 'picked.png');
  }
}

/// Installs [FakeFileSelector] and returns the previous instance so the
/// caller can restore it (e.g. via `addTearDown`).
FileSelectorPlatform installFakeFileSelector([Uint8List? bytes]) {
  final previous = FileSelectorPlatform.instance;
  FileSelectorPlatform.instance = FakeFileSelector(bytes);
  return previous;
}
