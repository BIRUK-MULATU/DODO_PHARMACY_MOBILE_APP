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

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.args});
  final ResultsArgs args;

  @override
  Widget build(BuildContext context) {
    // Scale the sample score up to the full bank for a satisfying headline.
    final scaled =
        ((args.correct / args.answered) * args.pack.questionCount).round();

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
                    value: scaled,
                    suffix: ' / ${args.pack.questionCount}',
                    duration: const Duration(milliseconds: 1500),
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                Entrance(
                  delay: const Duration(milliseconds: 500),
                  child: const Text('Well done!',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
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
          const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}
