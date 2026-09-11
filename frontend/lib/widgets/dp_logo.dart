import 'package:flutter/material.dart';

import 'assets.dart';

/// The DODOMED "dp" pill mark (`assets/images/logo.png`).
///
/// On light surfaces leave [color] null to show the artwork as-is. On dark
/// surfaces pass a [color] (usually yellow) to tint the mark so it stays legible.
/// [progress] 0..1 is a simple scale/opacity reveal used by the splash screen.
class DpLogo extends StatelessWidget {
  const DpLogo({
    super.key,
    this.size = 96,
    this.color,
    this.progress = 1,
  });

  final double size;
  final Color? color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    return Opacity(
      opacity: t,
      child: Transform.scale(
        scale: 0.85 + 0.15 * t,
        child: Image.asset(
          Img.logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: color,
          colorBlendMode: color != null ? BlendMode.srcIn : null,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
