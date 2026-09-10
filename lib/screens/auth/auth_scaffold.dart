import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dp_logo.dart';
import '../../widgets/entrance.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/wave.dart';

/// Shared shell for the Login and Sign-up screens: a dark illustration band
/// with a wavy bottom, then the yellow form area.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.hero,
    required this.title,
    required this.fields,
    required this.primary,
    required this.footer,
    this.beforePrimary,
  });

  final String hero;
  final String title;
  final List<Widget> fields;
  final Widget primary;
  final Widget footer;
  final Widget? beforePrimary;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipPath(
              clipper: BottomWaveClipper(dip: 44, rise: 26),
              child: Container(
                height: 320 + topPad,
                width: double.infinity,
                color: AppColors.ink,
                padding: EdgeInsets.only(top: topPad + 8),
                child: Stack(
                  children: [
                    Positioned(
                      top: 14,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const DpLogo(size: 34),
                      ),
                    ),
                    Entrance(
                      offset: const Offset(0, -20),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Image.asset(hero, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Entrance(
                    child: Text(title, style: AppTheme.display),
                  ),
                  const SizedBox(height: 18),
                  ...staggered(
                    fields,
                    start: const Duration(milliseconds: 120),
                    step: const Duration(milliseconds: 80),
                  ).expand((w) => [w, const SizedBox(height: 12)]),
                  ?beforePrimary,
                  const SizedBox(height: 8),
                  Entrance(
                    delay: const Duration(milliseconds: 380),
                    child: primary,
                  ),
                  const SizedBox(height: 18),
                  const _OrDivider(),
                  const SizedBox(height: 16),
                  Entrance(
                    delay: const Duration(milliseconds: 460),
                    child: const GoogleButton(),
                  ),
                  const SizedBox(height: 18),
                  Center(child: footer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppColors.ink, thickness: 1.4)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
        Expanded(child: Divider(color: AppColors.ink, thickness: 1.4)),
      ],
    );
  }
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('G',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink)),
            SizedBox(width: 14),
            Text('Log in with google',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text,
            style:
                const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(width: 8),
        PressScale(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(action,
                style: const TextStyle(
                    color: AppColors.yellow, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
