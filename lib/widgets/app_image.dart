import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renders an image that is either a bundled asset (`assets/...`) or one the
/// admin picked from their device, stored inline as a `data:` URI.
class AppImage extends StatelessWidget {
  const AppImage(
    this.source, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String source;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  static final Map<String, Uint8List> _cache = {};

  static bool isUploaded(String src) => src.startsWith('data:');

  static Uint8List? _bytes(String src) {
    if (!src.startsWith('data:')) return null;
    return _cache.putIfAbsent(src, () {
      final comma = src.indexOf(',');
      return base64Decode(src.substring(comma + 1));
    });
  }

  /// An [ImageProvider] for a bundled asset path or an uploaded `data:` URI —
  /// for `DecorationImage`, `CircleAvatar`, etc.
  static ImageProvider provider(String source) {
    final bytes = _bytes(source);
    if (bytes != null) return MemoryImage(bytes);
    return AssetImage(source);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes(source);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (_, _, _) => _broken(),
      );
    }
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (_, _, _) => _broken(),
      );
    }
    return _broken();
  }

  Widget _broken() => Container(
        width: width,
        height: height,
        color: const Color(0x11000000),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            color: Colors.black26, size: 20),
      );
}

const _imageGroup = XTypeGroup(
  label: 'Images',
  extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
  mimeTypes: ['image/png', 'image/jpeg', 'image/webp', 'image/gif', 'image/bmp'],
  uniformTypeIdentifiers: ['public.image'],
);

/// Opens the device image picker and returns the chosen image as a `data:` URI
/// (downscaled so a full-size photo doesn't blow up memory). Returns null if the
/// user cancels.
Future<String?> pickImageAsDataUri({int maxWidth = 1100}) async {
  final file = await openFile(acceptedTypeGroups: const [_imageGroup]);
  if (file == null) return null;
  var bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;

  try {
    final probe = await ui.instantiateImageCodec(bytes);
    final frame = await probe.getNextFrame();
    final tooWide = frame.image.width > maxWidth;
    frame.image.dispose();
    if (tooWide) {
      final scaled = await ui.instantiateImageCodec(bytes, targetWidth: maxWidth);
      final sframe = await scaled.getNextFrame();
      final data =
          await sframe.image.toByteData(format: ui.ImageByteFormat.png);
      sframe.image.dispose();
      if (data != null) {
        return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List())}';
      }
    }
  } catch (_) {
    // fall through and use the original bytes
  }
  final mime = _mimeForName(file.name);
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

String _mimeForName(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.gif')) return 'image/gif';
  if (n.endsWith('.bmp')) return 'image/bmp';
  return 'image/jpeg';
}

/// A horizontal image chooser for the admin forms: an "Upload from device" tile,
/// the current custom image (if any), then the bundled presets.
class ImagePickerRow extends StatelessWidget {
  const ImagePickerRow({
    super.key,
    required this.bundled,
    required this.selected,
    required this.onSelected,
    this.tileWidth = 84,
    this.tileHeight = 84,
    this.allowNone = false,
  });

  final List<String> bundled;
  final String selected;
  final ValueChanged<String> onSelected;
  final double tileWidth;
  final double tileHeight;
  final bool allowNone;

  bool get _hasCustom => AppImage.isUploaded(selected);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tileHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _UploadTile(
            width: tileWidth,
            height: tileHeight,
            onPick: () async {
              final uri = await pickImageAsDataUri();
              if (uri != null) onSelected(uri);
            },
          ),
          if (allowNone) ...[
            const SizedBox(width: 10),
            _Tile(
              width: tileWidth,
              height: tileHeight,
              selected: selected.isEmpty,
              onTap: () => onSelected(''),
              child: const Center(
                child: Text('None',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ],
          if (_hasCustom) ...[
            const SizedBox(width: 10),
            _Tile(
              width: tileWidth,
              height: tileHeight,
              selected: true,
              onTap: () {},
              child: AppImage(selected, fit: BoxFit.cover),
            ),
          ],
          for (final img in bundled) ...[
            const SizedBox(width: 10),
            _Tile(
              width: tileWidth,
              height: tileHeight,
              selected: selected == img,
              onTap: () => onSelected(img),
              child: AppImage(img, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.width,
    required this.height,
    required this.onPick,
  });

  final double width;
  final double height;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: AppColors.yellow, size: 22),
            SizedBox(height: 4),
            Text('Upload',
                style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.black12,
            width: selected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
