import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A one-shot confetti burst painted with a [CustomPainter] — no dependencies.
/// Place it in a [Stack] on top of a success screen.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.count = 90,
    this.duration = const Duration(milliseconds: 2600),
  });

  final int count;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Piece> _pieces;

  static const _palette = [
    AppColors.yellow,
    AppColors.ink,
    AppColors.correctFill,
    AppColors.successBadge,
    Colors.white,
    AppColors.wrongFill,
  ];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _pieces = List.generate(widget.count, (_) {
      return _Piece(
        angle: rnd.nextDouble() * 2 * math.pi,
        speed: 140 + rnd.nextDouble() * 340,
        size: 6 + rnd.nextDouble() * 9,
        rotation: rnd.nextDouble() * 2 * math.pi,
        spin: (rnd.nextDouble() - 0.5) * 12,
        color: _palette[rnd.nextInt(_palette.length)],
        drift: (rnd.nextDouble() - 0.5) * 60,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.color,
    required this.drift,
  });

  final double angle;
  final double speed;
  final double size;
  final double rotation;
  final double spin;
  final Color color;
  final double drift;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.36);
    final gravity = 520.0;
    final time = t * 2.6;
    final fade = (1 - t).clamp(0.0, 1.0);

    for (final p in pieces) {
      final vx = math.cos(p.angle) * p.speed + p.drift;
      final vy = math.sin(p.angle) * p.speed - 120;
      final x = origin.dx + vx * time;
      final y = origin.dy + vy * time + 0.5 * gravity * time * time;
      if (y > size.height + 20) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.spin * time);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
