import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/assets.dart';
import '../widgets/entrance.dart';
import '../widgets/swipe_to_start.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Entrance(
                    child: Text('WELCOME  TO', style: AppTheme.display),
                  ),
                  const SizedBox(height: 14),
                  Entrance(
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                      'We’re thrilled to support your lifelong learning and clinical excellence.',
                      style: AppTheme.h2.copyWith(height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Entrance(
                delay: Duration(milliseconds: 240),
                offset: Offset(0, 40),
                child: _HeroStage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Entrance(
                delay: const Duration(milliseconds: 420),
                child: SwipeToStart(
                  label: 'Swipe to get started',
                  onComplete: () => Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.login),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The animated welcome illustration: a slowly-morphing black blob with the
/// pharmacist cut-out (transparent PNG — no rectangle) floating over it.
class _HeroStage extends StatefulWidget {
  const _HeroStage();

  @override
  State<_HeroStage> createState() => _HeroStageState();
}

class _HeroStageState extends State<_HeroStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 * math.pi;
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Morphing blob.
            Positioned.fill(
              child: CustomPaint(
                painter: _BlobPainter(_c.value),
              ),
            ),
            // Floating, gently swaying pharmacist.
            Transform.translate(
              offset: Offset(
                math.sin(t * 0.7) * 6,
                math.sin(t) * 9 - 4,
              ),
              child: Transform.rotate(
                angle: math.sin(t * 0.5) * 0.02,
                child: Transform.scale(
                  scale: 1 + math.sin(t * 1.3) * 0.012,
                  child: Image.asset(
                    Img.pharmacist,
                    fit: BoxFit.contain,
                    height: h * 0.58,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink;
    final center = Offset(size.width / 2, size.height * 0.46);
    final radius = math.min(size.width, size.height) * 0.48;
    final ph = phase * 2 * math.pi;

    const points = 10;
    final pts = <Offset>[];
    for (var i = 0; i < points; i++) {
      final a = (i / points) * 2 * math.pi;
      final wobble = 1 +
          0.16 * math.sin(a * 3 + ph) +
          0.10 * math.cos(a * 2 - ph * 1.3) +
          0.06 * math.sin(a * 5 + ph * 0.5);
      pts.add(Offset(
        center.dx + math.cos(a) * radius * wobble * 1.15,
        center.dy + math.sin(a) * radius * wobble,
      ));
    }

    // Smooth closed curve through the points.
    final path = Path()
      ..moveTo(
        (pts[0].dx + pts.last.dx) / 2,
        (pts[0].dy + pts.last.dy) / 2,
      );
    for (var i = 0; i < pts.length; i++) {
      final cur = pts[i];
      final next = pts[(i + 1) % pts.length];
      path.quadraticBezierTo(
        cur.dx,
        cur.dy,
        (cur.dx + next.dx) / 2,
        (cur.dy + next.dy) / 2,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.phase != phase;
}
