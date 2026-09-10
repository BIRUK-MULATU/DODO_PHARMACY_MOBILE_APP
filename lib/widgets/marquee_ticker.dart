import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The looping "What We Offer …" promo strip that sits under every dark header.
class MarqueeTicker extends StatefulWidget {
  const MarqueeTicker({
    super.key,
    this.text =
        '🔥 What We Offer - 2027 Pharmacy Exit Exam: 3,000+ targeted sample questions with detailed explanations',
    this.background = AppColors.ink,
    this.foreground = AppColors.yellow,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Nunito',
      color: widget.foreground,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    final label = '${widget.text}        ';

    // Measure one label so we can translate by exactly its width -> seamless.
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final segment = painter.width;

    return Container(
      height: 40,
      decoration: BoxDecoration(color: widget.background),
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.centerLeft,
      child: OverflowBox(
        maxWidth: double.infinity,
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(-_c.value * segment, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) Text(label, style: style),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
