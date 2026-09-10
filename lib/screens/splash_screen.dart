import 'dart:async';

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/dp_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  late final Animation<double> _assemble = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  );
  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 2400), _next);
  }

  void _next() {
    if (!mounted) return;
    // Don't hijack navigation if we're no longer the visible route
    // (e.g. deep-linked straight past the splash).
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final loggedIn = AppStateScope.read(context).loggedIn;
    Navigator.of(context).pushReplacementNamed(
      loggedIn ? AppRoutes.home : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DpLogo(size: 160, progress: _assemble.value),
                const SizedBox(height: 18),
                Opacity(
                  opacity: _wordmark.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _wordmark.value) * 12),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 3),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.ink, width: 2.5),
                        ),
                      ),
                      child: const Text(
                        'DODOMED',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
