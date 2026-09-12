import 'package:flutter/material.dart';

import '../../app/routes.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'package:dodomed_core/widgets/app_image.dart';
import 'admin_scaffold.dart';

/// Full CRUD over the exam packs (e.g. "3000 Exit Question Sample Exam",
/// "2800 COC Sample Question Exam"). A teacher can add as many as they like.
class AdminPacksScreen extends StatelessWidget {
  const AdminPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final packs = state.examPacks;

    return AdminScaffold(
      title: 'Exam packs (${packs.length})',
      onBack: () => Navigator.of(context).maybePop(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.yellow,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminPackForm),
        icon: const Icon(Icons.add),
        label: const Text('New pack',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: packs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No exam packs yet.\nTap “New pack” to add one — give it a '
                  'title, a track, a price and a free-question limit.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: packs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = packs[i];
                final authored = state.questionsForPack(p.id).length;
                return _PackCard(
                  pack: p,
                  trackName: state.trackName(p.trackId),
                  authored: authored,
                  onEdit: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminPackForm, arguments: p),
                  onDelete: () => _confirmDelete(context, state, p, authored),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, ExamPack p, int authored) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete pack?'),
        content: Text(
          '“${p.title}” will be removed'
          '${authored > 0 ? ', along with its $authored authored question(s)' : ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.wrong),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      state.deletePack(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pack deleted')),
        );
      }
    }
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.trackName,
    required this.authored,
    required this.onEdit,
    required this.onDelete,
  });

  final ExamPack pack;
  final String trackName;
  final int authored;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppImage(
                      pack.image,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pack.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${pack.trackId.isEmpty ? '—' : trackName} · ${pack.id}',
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.45),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.wrong),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _kv('Price', 'ETB ${pack.priceBirr}'),
                  _kv('Free', '${pack.freeLimit}'),
                  _kv('Bank size', '${pack.questionCount}'),
                  _kv('Authored', '$authored'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v,
                style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
            Text(k,
                style: TextStyle(
                    color: AppColors.yellow.withValues(alpha: 0.7),
                    fontSize: 10)),
          ],
        ),
      );
}
