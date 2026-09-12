import 'package:flutter/material.dart';

/// Fade + slide-up entrance animation that plays once when the widget mounts.
/// Drop it around any child and stagger a list by increasing [delay].
///
/// The delay is baked into the controller as an [Interval] rather than a timer
/// so the animation can never get stuck partway.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = const Offset(0, 26),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final startFraction = total.inMicroseconds == 0
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(startFraction, 1, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        return Opacity(
          opacity: _t.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(
              widget.offset.dx * (1 - _t.value),
              widget.offset.dy * (1 - _t.value),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Convenience: wrap each child of a column in a staggered [Entrance].
List<Widget> staggered(
  List<Widget> children, {
  Duration start = const Duration(milliseconds: 60),
  Duration step = const Duration(milliseconds: 80),
}) {
  return [
    for (var i = 0; i < children.length; i++)
      Entrance(delay: start + step * i, child: children[i]),
  ];
}
