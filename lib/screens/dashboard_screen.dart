import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_bits.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/assets.dart';
import '../widgets/entrance.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/press_scale.dart';
import '../widgets/wave.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final pack = state.primaryPack;
    final answered = state.answered(pack.id);
    final pct = (state.progress(pack) * 100).round();
    final accuracy = state.accuracyPercent;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      drawer: const AppDrawer(),
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(current: 1),
      body: Builder(
        builder: (context) => CustomScrollView(
          slivers: [
            SliverPinnedHeader(
              height: 180,
              child: WaveHeader(
                height: 180,
                title: 'Dashboard',
                onMenu: () => Scaffold.of(context).openDrawer(),
                avatar: const AssetImage(Img.avatar),
                onAvatarTap: () =>
                    AppRoutes.goToSection(context, AppRoutes.profile),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  height: 116,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Answered',
                          value: answered),
                      _StatCard(
                          icon: Icons.percent,
                          label: 'Accuracy',
                          value: accuracy,
                          suffix: '%'),
                      _StatCard(
                          icon: Icons.local_fire_department,
                          label: 'Best Streak',
                          value: state.totalCorrect),
                      _StatCard(
                          icon: Icons.workspace_premium,
                          label: 'Rank',
                          value: 12),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: MarqueeTicker()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              sliver: SliverList.list(
                children: staggered([
                  _ProgressHero(
                    percent: pct,
                    onContinue: () => Navigator.of(context)
                        .pushNamed(AppRoutes.exam, arguments: pack),
                  ),
                  const SizedBox(height: 18),
                  _Panel(
                    title: 'Exam Readiness',
                    child: _ReadinessGauge(value: (accuracy / 100).clamp(0, 1)),
                  ),
                  const SizedBox(height: 18),
                  const _Panel(
                    title: 'This Week',
                    child: _WeeklyBars(),
                  ),
                  const SizedBox(height: 18),
                  const _Panel(
                    title: 'Recent Activity',
                    child: _RecentActivity(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final int value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.yellow, size: 20),
          CountUp(
            value: value,
            suffix: suffix,
            style: const TextStyle(
                color: AppColors.yellow,
                fontSize: 22,
                fontWeight: FontWeight.w900),
          ),
          Text(label,
              style: TextStyle(
                  color: AppColors.yellow.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.percent, required this.onContinue});
  final int percent;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.yellowDeep, AppColors.yellowOlive],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3000 Exit Exam Sample Question',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          CountUp(
            value: percent,
            suffix: '%',
            style:
                const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
          ),
          const Text('Great Progress',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          AnimatedProgressBar(value: percent / 100, height: 10),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: PressScale(
              onTap: onContinue,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.correctFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(width: 6),
                    Icon(Icons.play_arrow_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReadinessGauge extends StatelessWidget {
  const _ReadinessGauge({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return SizedBox(
          height: 130,
          child: CustomPaint(
            painter: _GaugePainter(v),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(v * 100).round()}',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900)),
                    Text(
                      v < 0.4
                          ? 'Keep practising'
                          : v < 0.75
                              ? 'On track'
                              : 'Exam ready',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(10, 10, size.width - 20, (size.width - 20));
    final center = Offset(size.width / 2, size.width / 2 - 5 + 10);
    final radius = (size.width - 20) / 2;
    final track = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.12)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), math.pi, math.pi,
        false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi,
        math.pi * value, false, fill);
    // silence unused
    rect.toString();
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars();

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const values = [0.4, 0.75, 0.55, 0.9, 0.65, 0.3, 0.8];
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < days.length; i++)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: values[i]),
                  duration: Duration(milliseconds: 700 + i * 90),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Container(
                    width: 22,
                    height: 90 * v,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(days[i],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Pharmacology', 'Correct', true),
      ('Clinical Pharmacy', 'Wrong', false),
      ('Public Health', 'Correct', true),
    ];
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(r.$3 ? Icons.check_circle : Icons.cancel,
                    color: r.$3 ? AppColors.correct : AppColors.wrong,
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(r.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(r.$2,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: r.$3 ? AppColors.correct : AppColors.wrong)),
              ],
            ),
          ),
      ],
    );
  }
}
