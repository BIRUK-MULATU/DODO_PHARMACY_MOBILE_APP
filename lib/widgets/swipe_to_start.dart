import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'dp_logo.dart';

/// Slide-to-unlock style control: drag the yellow thumb across the track to
/// fire [onComplete]. Springs back if released before the threshold.
class SwipeToStart extends StatefulWidget {
  const SwipeToStart({
    super.key,
    required this.onComplete,
    this.label = 'Swipe to get started',
    this.height = 66,
  });

  final VoidCallback onComplete;
  final String label;
  final double height;

  @override
  State<SwipeToStart> createState() => _SwipeToStartState();
}

class _SwipeToStartState extends State<SwipeToStart>
    with TickerProviderStateMixin {
  static const _threshold = 0.72;

  /// Animates the thumb between drag-release positions (0..1 of the track).
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() => setState(() {}));

  /// Idle hint — a gentle nudge + chevron shimmer.
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  double _drag = 0; // 0..1 while dragging
  bool _dragging = false;
  bool _done = false;

  double get _progress => _dragging ? _drag : _slide.value;

  @override
  void dispose() {
    _slide.dispose();
    _hint.dispose();
    super.dispose();
  }

  void _release() {
    final from = _drag;
    setState(() => _dragging = false);
    _slide
      ..stop()
      ..value = from;
    if (from >= _threshold) {
      _done = true;
      _slide
          .animateTo(1,
              curve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 200))
          .then((_) => widget.onComplete());
    } else {
      _slide.animateTo(0,
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 520));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final thumb = h - 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final travel = constraints.maxWidth - thumb - 10;
        final x = _progress * travel;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _done
              ? null
              : (_) {
                  setState(() {
                    _dragging = true;
                    _drag = _progress;
                  });
                },
          onHorizontalDragUpdate: _done
              ? null
              : (d) {
                  setState(() {
                    _drag = (_drag + d.delta.dx / travel).clamp(0.0, 1.0);
                  });
                },
          onHorizontalDragEnd: _done ? null : (_) => _release(),
          onHorizontalDragCancel: _done ? null : _release,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(h / 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Label + chevrons, fading out as the thumb advances.
                Opacity(
                  opacity: (1 - _progress * 1.6).clamp(0.0, 1.0),
                  child: Padding(
                    padding: EdgeInsets.only(left: thumb * 0.7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: AppColors.yellow,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Chevrons(progress: _hint),
                      ],
                    ),
                  ),
                ),
                // Filled trail behind the thumb.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: x + thumb + 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(h / 2),
                    ),
                  ),
                ),
                // Draggable thumb.
                AnimatedBuilder(
                  animation: _hint,
                  builder: (context, child) {
                    final nudge = (_dragging || _done)
                        ? 0.0
                        : math.sin(_hint.value * math.pi * 2).clamp(0.0, 1.0) *
                            8;
                    return Positioned(
                      left: 5 + x + nudge,
                      child: child!,
                    );
                  },
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: const BoxDecoration(
                      color: AppColors.yellow,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _done
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.ink, size: 26)
                        : DpLogo(size: thumb * 0.56),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chevrons extends StatelessWidget {
  const _Chevrons({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (progress.value * 3 - i).clamp(0.0, 1.0);
            final o = (math.sin(phase * math.pi)).clamp(0.0, 1.0);
            return Opacity(
              opacity: 0.25 + o * 0.75,
              child: const Icon(Icons.chevron_right,
                  color: AppColors.yellow, size: 20),
            );
          }),
        );
      },
    );
  }
}
