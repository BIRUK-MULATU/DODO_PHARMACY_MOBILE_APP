import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_bits.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/entrance.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/press_scale.dart';
import '../widgets/wave.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final packs = state.visiblePacks;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      drawer: const AppDrawer(),
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(current: 0),
      body: Builder(
        builder: (context) => CustomScrollView(
          slivers: [
            SliverPinnedHeader(
              height: 230,
              child: WaveHeader(
                height: 230,
                greeting: 'Hello! Aster!',
                headline: '2027 Huge discount for COC Examiner',
                onMenu: () => Scaffold.of(context).openDrawer(),
                avatar: AssetImage(state.profile.avatar),
                onAvatarTap: () =>
                    AppRoutes.goToSection(context, AppRoutes.profile),
              ),
            ),
            const SliverToBoxAdapter(child: MarqueeTicker()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
              sliver: SliverList.list(
                children: [
                  if (packs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        'No exam packs yet.\nAn admin can add them from the '
                        'admin panel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  for (var i = 0; i < packs.length; i++)
                    Entrance(
                      delay: Duration(milliseconds: 120 + i * 130),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _ExamBanner(
                          pack: packs[i],
                          progress: state.progress(packs[i]),
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.about,
                            arguments: packs[i],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamBanner extends StatelessWidget {
  const _ExamBanner({
    required this.pack,
    required this.progress,
    required this.onTap,
  });

  final ExamPack pack;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.97,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          color: AppColors.yellowDeep,
          child: Column(
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(pack.image, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x66000000)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnYellow,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedProgressBar(value: progress, height: 10),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(progress * 100).round()}% complete',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnYellow)),
                        const Row(
                          children: [
                            Text('Start ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnYellow)),
                            Icon(Icons.play_circle_fill,
                                size: 20, color: AppColors.ink),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
