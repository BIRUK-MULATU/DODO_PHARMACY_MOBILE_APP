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
            Expanded(
              child: Entrance(
                delay: const Duration(milliseconds: 260),
                offset: const Offset(0, 40),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _FloatY(
                    child: Image.asset(
                      Img.onboardingHero,
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.5,
                    ),
                  ),
                ),
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

/// Slow vertical bob for hero art.
class _FloatY extends StatefulWidget {
  const _FloatY({required this.child});
  final Widget child;

  @override
  State<_FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<_FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 + _c.value * 12),
        child: child,
      ),
      child: widget.child,
    );
  }
}
