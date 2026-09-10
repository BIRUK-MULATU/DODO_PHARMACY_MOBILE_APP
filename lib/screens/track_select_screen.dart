import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/assets.dart';
import '../widgets/entrance.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/press_scale.dart';
import '../widgets/wave.dart';

class TrackSelectScreen extends StatelessWidget {
  const TrackSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    void pick(ExamTrack track) {
      state.chooseTrack(track);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }

    return Scaffold(
      backgroundColor: AppColors.yellow,
      drawer: const AppDrawer(),
      body: Builder(
        builder: (context) => CustomScrollView(
          slivers: [
            SliverPinnedHeader(
              height: 250,
              child: WaveHeader(
                height: 250,
                greeting: 'Hello! Aster!',
                headline: 'What would you like to learn to day?',
                onMenu: () => Scaffold.of(context).openDrawer(),
                avatar: const AssetImage(Img.avatar),
                onAvatarTap: () =>
                    AppRoutes.goToSection(context, AppRoutes.profile),
                trailingLogo: true,
              ),
            ),
            const SliverToBoxAdapter(child: MarqueeTicker()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              sliver: SliverList.list(
                children: [
                  Entrance(
                    delay: const Duration(milliseconds: 120),
                    child: _TrackCard(
                      figure: Img.pharmacist,
                      label: 'Pharmacy',
                      onTap: () => pick(ExamTrack.pharmacy),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Entrance(
                    delay: const Duration(milliseconds: 240),
                    child: _TrackCard(
                      figure: Img.nurse,
                      label: 'Nursing',
                      onTap: () => pick(ExamTrack.nursing),
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

/// A choice card, laid out purely from its own width so both cards render
/// identically at any screen size: yellow scene → the figure → a name pill.
class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.figure,
    required this.label,
    required this.onTap,
  });

  final String figure;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.98,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 1.15, // width : height
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF4DE00), Color(0xFFD8C400)],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      figure,
                      height: c.maxHeight,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0, 0.2),
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x2B000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * 0.12,
                    right: w * 0.12,
                    bottom: w * 0.08,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: w * 0.045),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: w * 0.085,
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }
}
