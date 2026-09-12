import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'dp_logo.dart';

/// Clips the bottom edge of a box into the soft double-wave seen on every
/// header / section transition in the design.
class BottomWaveClipper extends CustomClipper<Path> {
  BottomWaveClipper({this.dip = 34, this.rise = 18});

  final double dip;
  final double rise;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - dip)
      ..cubicTo(
        size.width * 0.22,
        size.height + rise,
        size.width * 0.42,
        size.height - dip - rise,
        size.width * 0.62,
        size.height - dip * 0.4,
      )
      ..cubicTo(
        size.width * 0.80,
        size.height - dip * 0.1 + rise,
        size.width * 0.92,
        size.height - dip * 1.3,
        size.width,
        size.height - dip * 0.9,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Clips the *top* edge into a wave — used where a yellow section meets a black
/// section below it.
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.16)
      ..cubicTo(
        size.width * 0.25,
        size.height * -0.02,
        size.width * 0.45,
        size.height * 0.22,
        size.width * 0.66,
        size.height * 0.12,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.04,
        size.width * 0.94,
        size.height * 0.20,
        size.width,
        size.height * 0.10,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A black header block with the wavy bottom edge. Optionally shows a menu
/// button, a title, and a circular avatar — matching the Home / Dashboard /
/// Profile headers.
class WaveHeader extends StatelessWidget {
  const WaveHeader({
    super.key,
    this.height = 220,
    this.title,
    this.greeting,
    this.headline,
    this.onMenu,
    this.onBack,
    this.avatar,
    this.onAvatarTap,
    this.trailingLogo = false,
    this.child,
  });

  final double height;
  final String? title;
  final String? greeting;
  final String? headline;
  final VoidCallback? onMenu;
  final VoidCallback? onBack;
  final ImageProvider? avatar;

  /// When set, tapping the header avatar runs this (used to open Profile).
  final VoidCallback? onAvatarTap;
  final bool trailingLogo;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipPath(
      clipper: BottomWaveClipper(),
      child: Container(
        height: height + topPad,
        width: double.infinity,
        color: AppColors.ink,
        padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 40),
        child:
            child ??
            Stack(
              children: [
                if (trailingLogo)
                  const Positioned(
                    right: 0,
                    bottom: 14,
                    child: DpLogo(size: 46, color: AppColors.yellow),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (onMenu != null)
                          _CircleTap(
                            onTap: onMenu!,
                            child: const Icon(
                              Icons.menu,
                              color: AppColors.yellow,
                              size: 28,
                            ),
                          )
                        else if (onBack != null)
                          _CircleTap(
                            onTap: onBack!,
                            child: const Icon(
                              Icons.chevron_left,
                              color: AppColors.yellow,
                              size: 32,
                            ),
                          ),
                        if (title != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.yellow,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (avatar != null)
                          GestureDetector(
                            onTap: onAvatarTap,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.yellow,
                                  width: 2.5,
                                ),
                                image: DecorationImage(
                                  image: avatar!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (greeting != null || headline != null)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: trailingLogo ? 54 : 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (greeting != null)
                                  Text(
                                    greeting!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.yellow
                                          .withValues(alpha: 0.65),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (headline != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      headline!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.yellow,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

/// Puts a [WaveHeader] into a `CustomScrollView` as a header that stays pinned
/// to the top while the rest of the content scrolls under it. [height] must be
/// the same value passed to the [WaveHeader].
class SliverPinnedHeader extends StatelessWidget {
  const SliverPinnedHeader({
    super.key,
    required this.child,
    required this.height,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final extent = height + MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(extent: extent, child: child),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) =>
      oldDelegate.extent != extent || oldDelegate.child != child;
}

class _CircleTap extends StatelessWidget {
  const _CircleTap({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(padding: const EdgeInsets.all(4), child: child),
    );
  }
}
