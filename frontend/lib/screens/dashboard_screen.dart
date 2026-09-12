import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_bits.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_image.dart';
import '../widgets/entrance.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/press_scale.dart';
import '../widgets/wave.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  RankFetch? _rank;
  DashboardActivity? _activity;
  bool _activityFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppStateScope.read(context);

    // Offline there's only ever one local/demo learner — fetchRank already
    // short-circuits to `1 of 1` without a network call, so this is cheap
    // and safe to always await. Fired in parallel with the activity fetch
    // below (rather than one-after-the-other) so the dashboard only waits
    // for the slower of the two round-trips, not both combined.
    final rankFuture = state.fetchRank().then((rank) {
      if (mounted) setState(() => _rank = rank);
    }).catchError((_) {
      // Leave _rank null — the stat card shows a loading placeholder
      // indefinitely rather than a wrong number.
    });

    final activityFuture = state.isOnline
        ? state.fetchDashboardActivity().then((activity) {
            if (mounted) setState(() => _activity = activity);
          }).catchError((_) {
            if (mounted) setState(() => _activityFailed = true);
          })
        : Future<void>.value();
    // Offline: `_activity` stays null, and `_WeeklyBars`/`_RecentActivity`
    // fall back to their own sample/demo content — there's no persisted
    // history to fetch when nothing survives a restart anyway.

    await Future.wait([rankFuture, activityFuture]);
  }

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
                avatar: AppImage.provider(state.profile.avatar),
                onAvatarTap: () =>
                    AppRoutes.goToSection(context, AppRoutes.profile),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
                child: SizedBox(
                  height: 132,
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
                          value: state.bestStreak),
                      _StatCard(
                          icon: Icons.workspace_premium,
                          label: 'Rank',
                          value: _rank?.rank),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: MarqueeTicker(text: state.aboutInfo.marqueeText)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              sliver: SliverList.list(
                children: staggered([
                  _ProgressHero(
                    title: pack.title,
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
                  _Panel(
                    title: 'Leaderboard',
                    child: _LeaderboardCard(rank: _rank),
                  ),
                  const SizedBox(height: 18),
                  _Panel(
                    title: 'This Week',
                    child: _WeeklyBars(days: _activity?.week),
                  ),
                  const SizedBox(height: 18),
                  _Panel(
                    title: 'Pack Progress',
                    child: _PackProgressList(state: state),
                  ),
                  const SizedBox(height: 18),
                  _Panel(
                    title: 'Recent Activity',
                    child: _RecentActivity(
                      entries: _activity?.recent,
                      failed: _activityFailed,
                    ),
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

  /// `null` shows a loading placeholder instead of an animated count —
  /// used for "Rank" while its real value is still being fetched.
  final int? value;
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
        children: [
          Icon(icon, color: AppColors.yellow, size: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value == null
                ? const Text('–',
                    style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 22,
                        fontWeight: FontWeight.w900))
                : CountUp(
                    value: value!,
                    suffix: suffix,
                    style: const TextStyle(
                        color: AppColors.yellow,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  const _ProgressHero({
    required this.title,
    required this.percent,
    required this.onContinue,
  });
  final String title;
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
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUp(
              value: percent,
              suffix: '%',
              style:
                  const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
            ),
          ),
          const Text('Great Progress',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        // A fixed drawing height, centered and capped to the available
        // width — so the arc's radius is always derived consistently from
        // both dimensions (the old version used the panel's full width for
        // the radius while the box was only 130px tall, so the arc ballooned
        // out and painted below/outside its own box).
        return SizedBox(
          height: 128,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: CustomPaint(
                painter: _GaugePainter(v),
                child: Align(
                  alignment: const Alignment(0, 0.45),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(v * 100).round()}',
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900)),
                      Text(
                        v < 0.4
                            ? 'Keep practising'
                            : v < 0.75
                                ? 'On track'
                                : 'Exam ready',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
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

  static const _strokeWidth = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    // The radius is capped by BOTH dimensions, so the arc (and its rounded
    // stroke caps) can never extend past the box it was actually given,
    // whatever size that box turns out to be.
    final radius = math.min(
      size.height - _strokeWidth,
      size.width / 2 - _strokeWidth / 2,
    );
    if (radius <= 0) return;
    final center = Offset(size.width / 2, size.height - _strokeWidth / 2);
    final track = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.12)
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = AppColors.ink
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), math.pi, math.pi,
        false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi,
        math.pi * value, false, fill);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}

/// New visualization: the caller's real leaderboard position (see
/// `GET /api/leaderboard/me`) — a rank badge plus a relative-position bar
/// among every learner on the account.
class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.rank});
  final RankFetch? rank;

  @override
  Widget build(BuildContext context) {
    final r = rank;
    if (r == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    // 1.0 = top of the leaderboard, 0.0 = bottom.
    final position =
        r.totalUsers <= 1 ? 1.0 : 1 - (r.rank - 1) / (r.totalUsers - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.ink, shape: BoxShape.circle),
              child: Text('#${r.rank}',
                  style: const TextStyle(
                      color: AppColors.yellow,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                r.totalUsers <= 1
                    ? "You're the only learner so far"
                    : 'Out of ${r.totalUsers} learners',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedProgressBar(value: position, height: 8),
      ],
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({this.days});

  /// Real per-day activity, oldest first. `null` (offline, or still loading
  /// online) falls back to a small sample pattern instead.
  final List<WeeklyActivityDay>? days;

  @override
  Widget build(BuildContext context) {
    const barAreaHeight = 90.0;
    final real = days;
    final labels = real != null
        ? real.map((d) => d.weekday).toList()
        : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final List<double> values;
    if (real != null) {
      final maxCount = real.fold<int>(0, (m, d) => math.max(m, d.count));
      values = real
          .map((d) => maxCount == 0 ? 0.04 : (d.count / maxCount).clamp(0.04, 1.0))
          .toList();
    } else {
      values = const [0.4, 0.75, 0.55, 0.9, 0.65, 0.3, 0.8];
    }

    return SizedBox(
      height: 120,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Bar width scales with the available space instead of a fixed
          // pixel value, so this stays proportioned on both a narrow phone
          // and a wide/tablet frame — clamped to a sane range either way.
          final barWidth =
              (constraints.maxWidth / labels.length * 0.5).clamp(14.0, 30.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < labels.length; i++)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: values[i]),
                      duration: Duration(milliseconds: 700 + i * 90),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        width: barWidth,
                        height: barAreaHeight * v,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i],
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// New visualization: a progress bar per exam pack, so a learner working
/// across several tracks/packs can see all of them at a glance instead of
/// only the primary one in the hero card above.
class _PackProgressList extends StatelessWidget {
  const _PackProgressList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final packs = state.examPacks;
    if (packs.isEmpty) {
      return const Text('No exam packs yet.',
          style: TextStyle(fontWeight: FontWeight.w600));
    }
    return Column(
      children: [
        for (var i = 0; i < packs.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == packs.length - 1 ? 0 : 14),
            child: _PackProgressRow(
              title: packs[i].title,
              value: state.progress(packs[i]),
            ),
          ),
      ],
    );
  }
}

class _PackProgressRow extends StatelessWidget {
  const _PackProgressRow({required this.title, required this.value});
  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Text('${(value * 100).round()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedProgressBar(value: value, height: 8),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({this.entries, this.failed = false});

  /// Real answer history, newest first. `null` (offline, or still loading
  /// online) falls back to a small sample instead.
  final List<ActivityEntry>? entries;
  final bool failed;

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final real = entries;

    if (real == null && failed) {
      return const Text("Couldn't load recent activity.",
          style: TextStyle(fontWeight: FontWeight.w600));
    }

    if (real != null) {
      if (real.isEmpty) {
        return const Text('Answer a question to see it here.',
            style: TextStyle(fontWeight: FontWeight.w600));
      }
      return Column(
        children: [
          for (final e in real.take(5))
            _ActivityRow(
              title: e.packTitle,
              correct: e.wasCorrect,
              trailing: _relativeTime(e.at),
            ),
        ],
      );
    }

    // Offline (or the online fetch hasn't resolved yet): a small sample so
    // the panel isn't empty while real history loads/doesn't exist.
    const rows = [
      ('Pharmacology', true),
      ('Clinical Pharmacy', false),
      ('Public Health', true),
    ];
    return Column(
      children: [
        for (final r in rows)
          _ActivityRow(title: r.$1, correct: r.$2),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.title, required this.correct, this.trailing});
  final String title;
  final bool correct;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel,
              color: correct ? AppColors.correct : AppColors.wrong, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(trailing ?? (correct ? 'Correct' : 'Wrong'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: correct ? AppColors.correct : AppColors.wrong)),
        ],
      ),
    );
  }
}
