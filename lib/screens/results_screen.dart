import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_bits.dart';
import '../widgets/assets.dart';
import '../widgets/confetti.dart';
import '../widgets/entrance.dart';
import '../widgets/primary_button.dart';

class ResultsArgs {
  const ResultsArgs({
    required this.pack,
    required this.correct,
    required this.answered,
  });

  final ExamPack pack;
  final int correct;
  final int answered;
}

/// A performance tier for the results screen — graded on accuracy, with an
/// honest label and message instead of one generic "Well done!" no matter
/// how the learner actually did.
class _Grade {
  const _Grade(this.label, this.message, this.color);
  final String label;
  final String message;
  final Color color;

  static _Grade forAccuracy(int accuracy) {
    if (accuracy >= 90) {
      return const _Grade(
          'Excellent!', 'You deserve it! 🏆', AppColors.correct);
    }
    if (accuracy >= 75) {
      return const _Grade(
          'Very Good!', 'Great performance — keep it up!', AppColors.correct);
    }
    if (accuracy >= 50) {
      return const _Grade('Good', 'Solid effort — keep practising to get '
          'even better.', AppColors.yellowOlive);
    }
    return const _Grade('Needs Improvement',
        "Don't worry — improve it! Review the explanations and try again.",
        AppColors.wrong);
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.args});
  final ResultsArgs args;

  @override
  Widget build(BuildContext context) {
    final accuracy =
        args.answered == 0 ? 0 : ((args.correct / args.answered) * 100).round();
    final grade = _Grade.forAccuracy(accuracy);

    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil(
                              AppRoutes.home, (r) => false),
                      icon: const Icon(Icons.chevron_left, size: 32),
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.grid_view_rounded, size: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Entrance(
                  child: Text(
                    'FINISHED !',
                    style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 8),
                Entrance(
                  delay: const Duration(milliseconds: 200),
                  child: CountUp(
                    value: args.correct,
                    suffix: ' / ${args.answered} correct',
                    duration: const Duration(milliseconds: 1500),
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 6),
                Entrance(
                  delay: const Duration(milliseconds: 350),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$accuracy% accuracy',
                        style: const TextStyle(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                Entrance(
                  delay: const Duration(milliseconds: 500),
                  child: Text(grade.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: grade.color)),
                ),
                const SizedBox(height: 4),
                Entrance(
                  delay: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(grade.message,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3)),
                  ),
                ),
                Expanded(
                  child: Entrance(
                    delay: const Duration(milliseconds: 350),
                    offset: const Offset(0, 40),
                    child: Image.asset(Img.celebrateHero,
                        fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Entrance(
                    delay: const Duration(milliseconds: 700),
                    child: PrimaryButton(
                      label: 'Back to Home',
                      withLogo: true,
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil(
                              AppRoutes.home, (r) => false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Only celebrate a decent result — confetti over a score that
          // needs improvement would feel dishonest.
          if (accuracy >= 50) const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}
