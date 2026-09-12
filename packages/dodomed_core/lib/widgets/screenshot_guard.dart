import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

import '../theme/app_colors.dart';

/// Wraps the app to block screenshots / screen recording.
///
/// On Android this turns on `FLAG_SECURE`, so the OS refuses the capture
/// outright (and shows its own "can't take screenshot" message). On iOS the
/// system can't be stopped, so the captured image comes out blank and — like
/// Android 14+ — a screenshot or a screen recording pops the dialog below.
/// No-op on web / desktop.
class ScreenshotGuard extends StatefulWidget {
  const ScreenshotGuard({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<ScreenshotGuard> createState() => _ScreenshotGuardState();
}

class _ScreenshotGuardState extends State<ScreenshotGuard> {
  final _noScreenshot = NoScreenshot.instance;
  StreamSubscription<ScreenshotSnapshot>? _sub;
  bool _dialogOpen = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_supported) _enable();
  }

  Future<void> _enable() async {
    try {
      await _noScreenshot.screenshotOff();
      await _noScreenshot.startScreenshotListening();
      _sub = _noScreenshot.screenshotStream.listen(_onEvent, onError: (_) {});
    } catch (_) {
      // Plugin channel not available (tests / unsupported platform).
    }
  }

  void _onEvent(ScreenshotSnapshot snap) {
    if (snap.wasScreenshotTaken || snap.isScreenRecording) _warn();
  }

  void _warn() {
    if (_dialogOpen) return;
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    _dialogOpen = true;
    showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.yellow,
        icon: const Icon(Icons.no_photography_rounded,
            color: AppColors.wrong, size: 40),
        title: const Text(
          'Screenshots are off',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'To protect the content, screenshots and screen recording are not '
          'allowed in DODOMED.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.yellow,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ).whenComplete(() => _dialogOpen = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (_supported) {
      _noScreenshot.screenshotOn().catchError((_) => false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
