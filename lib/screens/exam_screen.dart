import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_bits.dart';
import '../widgets/primary_button.dart';
import '../widgets/review_navigator_sheet.dart';
import '../widgets/wave.dart';
import 'results_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.pack});
  final ExamPack pack;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _index = 0;
  bool _forward = true;

  /// selected option per visited question index
  final Map<int, int> _selected = {};
  final Set<int> _answeredSet = {};
  final Set<int> _correctSet = {};

  ExamPack get pack => widget.pack;
  Question get q => AppStateScope.read(context).examQuestion(pack, _index);
  bool get answered => _answeredSet.contains(_index);
  int? get selected => _selected[_index];

  void _choose(int option) {
    if (answered) return;
    final wasCorrect = option == q.correctIndex;
    setState(() {
      _selected[_index] = option;
      _answeredSet.add(_index);
      if (wasCorrect) _correctSet.add(_index);
    });
    AppStateScope.read(context)
        .recordAnswer(packId: pack.id, wasCorrect: wasCorrect);
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, pack.questionCount - 1);
    if (next == _index) return;
    setState(() {
      _forward = delta > 0;
      _index = next;
    });
  }

  void _openPayment() {
    Navigator.of(context)
        .pushNamed(AppRoutes.payPrompt, arguments: pack)
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  void _jump(int target) {
    setState(() {
      _forward = target > _index;
      _index = target;
    });
  }

  void _finish() {
    final answeredCount = _answeredSet.length;
    final correct = _correctSet.length;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.results,
      arguments: ResultsArgs(
        pack: pack,
        correct: correct,
        answered: answeredCount == 0 ? 1 : answeredCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final topPad = MediaQuery.of(context).padding.top;
    final progress = (_index + (answered ? 1 : 0)) / pack.questionCount;
    final counter =
        '${(_index + 1).toString().padLeft(4, '0')}/${pack.questionCount}';

    // Free questions are used up and this one hasn't been answered yet.
    final locked = state.needsPayment(pack) && !answered;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Column(
        children: [
          // Header ---------------------------------------------------------
          ClipPath(
            clipper: BottomWaveClipper(dip: 30, rise: 16),
            child: Container(
              color: AppColors.ink,
              padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 46),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.yellow, size: 32),
                  ),
                  IconButton(
                    onPressed: _openNavigator,
                    icon: const Icon(Icons.grid_view_rounded,
                        color: AppColors.yellow, size: 28),
                  ),
                ],
              ),
            ),
          ),
          // Progress row --------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedProgressBar(
                    value: progress,
                    height: 14,
                    track: const Color(0xFF111111),
                    fill: AppColors.yellowSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Text(counter,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          // Question card ------------------------------------------------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              transitionBuilder: (child, anim) {
                final offset = Tween<Offset>(
                  begin: Offset(_forward ? 0.15 : -0.15, 0),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: SingleChildScrollView(
                key: ValueKey(_index),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: AppColors.ink, width: 1.5),
                            ),
                            child: Text(
                              'Question ${q.number} of ${q.total}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (answered)
                          _ResultBadge(correct: selected == q.correctIndex)
                        else if (locked)
                          const _LockChip(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      q.prompt,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (locked)
                      _Paywall(
                        pack: pack,
                        freeUsed: pack.freeLimit,
                        onPay: _openPayment,
                      )
                    else ...[
                      for (var i = 0; i < q.options.length; i++)
                        _OptionTile(
                          letter: String.fromCharCode(65 + i),
                          text: q.options[i],
                          state: _tileState(i),
                          onTap: () => _choose(i),
                        ),
                      if (answered) ...[
                        const SizedBox(height: 6),
                        _ExplanationCard(question: q),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Bottom bar -------------------------------------------------
          Container(
            color: AppColors.ink,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                _NavArrow(
                  icon: Icons.chevron_left,
                  onTap: _index == 0 ? null : () => _go(-1),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _finish,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag_rounded,
                              size: 20, color: AppColors.ink),
                          const SizedBox(width: 8),
                          Text('Finish  •  $counter',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
                _NavArrow(icon: Icons.chevron_right, onTap: () => _go(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TileState _tileState(int i) {
    if (!answered) return _TileState.idle;
    if (i == q.correctIndex) return _TileState.correct;
    if (i == selected) return _TileState.wrong;
    return _TileState.dimmed;
  }

  Future<void> _openNavigator() async {
    final target = await showReviewNavigator(
      context,
      total: pack.questionCount,
      current: _index,
      answered: _answeredSet,
      correct: _correctSet,
    );
    if (target != null) _jump(target);
  }
}

enum _TileState { idle, correct, wrong, dimmed }

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.correct});
  final bool correct;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, v, child) =>
          Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: correct ? AppColors.correct : AppColors.wrong,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(correct ? Icons.check_circle : Icons.cancel,
                color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(correct ? 'Right' : 'Wrong',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _TileState state;
  final VoidCallback onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant _OptionTile old) {
    super.didUpdateWidget(old);
    if (old.state != _TileState.wrong && widget.state == _TileState.wrong) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color border = AppColors.ink;
    double opacity = 1;
    Widget? icon;
    switch (widget.state) {
      case _TileState.idle:
        break;
      case _TileState.correct:
        bg = AppColors.correctFill;
        border = AppColors.correct;
        icon = const _StatusDot(color: AppColors.correct, icon: Icons.check);
        break;
      case _TileState.wrong:
        bg = AppColors.wrongFill;
        border = AppColors.wrongFill;
        icon = const _StatusDot(color: AppColors.wrong, icon: Icons.close);
        break;
      case _TileState.dimmed:
        opacity = 0.55;
        break;
    }

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx = math.sin(_shake.value * math.pi * 4) *
            10 *
            (1 - _shake.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: widget.state == _TileState.idle ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.6),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: 12),
                ] else ...[
                  Text('${widget.letter}) ',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
                Expanded(
                  child: Text(widget.text,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 20), child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.correctFill.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.correct, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Answer: ${question.answerLabel}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Explanation: ${question.explanation}',
              style: const TextStyle(
                  height: 1.5, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Icon(icon, color: AppColors.yellow, size: 34),
      ),
    );
  }
}

class _LockChip extends StatelessWidget {
  const _LockChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.wrongFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, color: AppColors.ink, size: 16),
          SizedBox(width: 6),
          Text('Locked',
              style:
                  TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Shown in place of the answer options once the free questions are used up.
class _Paywall extends StatelessWidget {
  const _Paywall({
    required this.pack,
    required this.freeUsed,
    required this.onPay,
  });

  final ExamPack pack;
  final int freeUsed;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, v, child) {
        final t = v.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.yellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.ink, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              "That's your $freeUsed free questions",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock all ${pack.questionCount} questions with detailed '
              'explanations to keep going.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Go to Payment  •  ${pack.priceBirr} Birr',
              style: DpButtonStyle.yellow,
              trailingIcon: Icons.lock_open_rounded,
              onPressed: onPay,
            ),
          ],
        ),
      ),
    );
  }
}
