import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confetti.dart';
import '../../widgets/entrance.dart';
import '../../widgets/press_scale.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key, required this.pack});

  final ExamPack pack;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Payment confirmed — unlock the pack now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.read(context).unlock(widget.pack.id);
    });
  }

  /// Unwind the whole payment stack and land back on the exam (or e-book /
  /// home) that started it — now unlocked.
  void _finish() {
    Navigator.of(context).popUntil((r) =>
        r.settings.name == AppRoutes.exam ||
        r.settings.name == AppRoutes.ebook ||
        r.settings.name == AppRoutes.ebookReader ||
        r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellowOlive,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: _BottomBlobClipper(),
              child: Container(height: 260, color: AppColors.ink),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 60,
            child: PressScale(
              onTap: _finish,
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.transparent,
                    child: Text('GO',
                        style: TextStyle(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w900)),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.yellow, size: 40),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, v, _) => Transform.scale(
                    scale: v,
                    child: CustomPaint(
                      size: const Size(150, 150),
                      painter: _SealPainter(),
                      child: const SizedBox(
                        width: 150,
                        height: 150,
                        child: Icon(Icons.check_rounded,
                            color: Colors.white, size: 66),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Entrance(
                  delay: Duration(milliseconds: 350),
                  child: Text('Payment successful',
                      style: TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 6),
                const Entrance(
                  delay: Duration(milliseconds: 450),
                  child: Text('Your transfer was successful',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 26),
                Entrance(
                  delay: const Duration(milliseconds: 550),
                  child: PressScale(
                    onTap: _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Text('Nice one!',
                          style: TextStyle(
                              color: AppColors.yellow,
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final inner = outer * 0.82;
    final path = Path();
    const teeth = 14;
    for (var i = 0; i < teeth * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = (i / (teeth * 2)) * 2 * math.pi;
      final p =
          Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = AppColors.successBadge);
    canvas.drawCircle(center, inner * 0.78,
        Paint()..color = Colors.white.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomBlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(size.width * 0.25, size.height * 0.1, size.width * 0.55,
          size.height * 0.9, size.width, size.height * 0.35)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
