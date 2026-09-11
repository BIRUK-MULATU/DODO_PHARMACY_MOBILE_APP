import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_image.dart';
import '../widgets/entrance.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/press_scale.dart';
import '../widgets/wave.dart';

class TrackSelectScreen extends StatelessWidget {
  const TrackSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final tracks = state.tracks;
    final firstName = state.profile.name.split(' ').first;

    void pick(String trackId) {
      state.chooseTrack(trackId);
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
                greeting: 'Hello! $firstName!',
                headline: 'What would you like to learn to day?',
                onMenu: () => Scaffold.of(context).openDrawer(),
                avatar: AppImage.provider(state.profile.avatar),
                onAvatarTap: () =>
                    AppRoutes.goToSection(context, AppRoutes.profile),
                trailingLogo: true,
              ),
            ),
            SliverToBoxAdapter(child: MarqueeTicker(text: state.aboutInfo.marqueeText)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              sliver: SliverList.list(
                children: [
                  for (var i = 0; i < tracks.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    Entrance(
                      delay: Duration(milliseconds: 120 + i * 120),
                      child: _TrackCard(
                        figure: tracks[i].figure,
                        label: tracks[i].name,
                        onTap: () => pick(tracks[i].id),
                      ),
                    ),
                  ],
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
                  if (figure.isNotEmpty)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AppImage(
                        figure,
                        height: c.maxHeight,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.school_rounded,
                        size: w * 0.34,
                        color: AppColors.ink.withValues(alpha: 0.35),
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
