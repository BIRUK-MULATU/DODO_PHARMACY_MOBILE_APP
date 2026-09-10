import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Read-only overview of the exam packs (price, free limit, question counts).
/// Packs are fixed content in this build; editing them would need a backend.
class AdminPacksScreen extends StatelessWidget {
  const AdminPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return AdminScaffold(
      title: 'Exam packs',
      onBack: () => Navigator.of(context).maybePop(),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: MockData.examPacks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = MockData.examPacks[i];
          final authored = state.questionsForPack(p.id).length;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(p.id,
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.45),
                        fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _kv('Price', 'ETB ${p.priceBirr}'),
                    _kv('Free questions', '${p.freeLimit}'),
                    _kv('Bank total', '${p.questionCount}'),
                    _kv('Authored', '$authored'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v,
                style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
            Text(k,
                style: TextStyle(
                    color: AppColors.yellow.withValues(alpha: 0.7),
                    fontSize: 10)),
          ],
        ),
      );
}
