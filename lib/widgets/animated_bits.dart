import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A progress bar that animates from 0 to [value] (0..1) whenever it appears or
/// [value] changes.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.track = const Color(0x33000000),
    this.fill = AppColors.ink,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final double height;
  final Color track;
  final Color fill;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Container(
            height: height,
            color: track,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v == 0 ? 0.0001 : v,
                child: Container(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(height),
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

/// Counts up to [value] with an easing curve. Great for stat cards & results.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1100),
  });

  final num value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final text = value is int || value == v.roundToDouble()
            ? v.round().toString()
            : v.toStringAsFixed(1);
        return Text('$prefix$text$suffix', style: style);
      },
    );
  }
}

/// Pulsing scale used to draw attention to primary CTAs.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.min = 0.98, this.max = 1.03});
  final Widget child;
  final double min;
  final double max;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: widget.min, end: widget.max).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
