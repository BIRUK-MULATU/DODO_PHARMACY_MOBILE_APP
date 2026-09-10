import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'entrance.dart';
import 'press_scale.dart';

/// Draggable bottom sheet with a grid of question chips. Returns the tapped
/// question index (0-based) via [Navigator.pop].
Future<int?> showReviewNavigator(
  BuildContext context, {
  required int total,
  required int current,
  required Set<int> answered,
  required Set<int> correct,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _ReviewNavigatorSheet(
      total: total,
      current: current,
      answered: answered,
      correct: correct,
    ),
  );
}

class _ReviewNavigatorSheet extends StatelessWidget {
  const _ReviewNavigatorSheet({
    required this.total,
    required this.current,
    required this.answered,
    required this.correct,
  });

  final int total;
  final int current;
  final Set<int> answered;
  final Set<int> correct;

  @override
  Widget build(BuildContext context) {
    final count = total.clamp(0, 60);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.yellowOlive,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Review Navigator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: count,
                  itemBuilder: (context, i) {
                    final isCurrent = i == current;
                    final isAnswered = answered.contains(i);
                    final isCorrect = correct.contains(i);
                    Color bg = AppColors.ink;
                    Color fg = AppColors.yellow;
                    if (isAnswered) {
                      bg = isCorrect
                          ? AppColors.correct
                          : AppColors.wrong;
                      fg = Colors.white;
                    }
                    return Entrance(
                      delay: Duration(milliseconds: 20 * i),
                      offset: const Offset(0, 12),
                      child: PressScale(
                        onTap: () => Navigator.of(context).pop(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrent
                                ? Border.all(color: AppColors.ink, width: 3)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: fg,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
