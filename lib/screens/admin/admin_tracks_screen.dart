import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Full CRUD over the tracks (fields of study) shown on the "what would you
/// like to learn" screen — Pharmacy, Nursing, and any more the admin adds.
class AdminTracksScreen extends StatelessWidget {
  const AdminTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final tracks = state.tracks;

    return AdminScaffold(
      title: 'Tracks (${tracks.length})',
      onBack: () => Navigator.of(context).maybePop(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.yellow,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminTrackForm),
        icon: const Icon(Icons.add),
        label: const Text('New track',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: tracks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tracks yet.\nTap “New track” to add one (e.g. Pharmacy, '
                  'Nursing, Midwifery).',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: tracks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final t = tracks[i];
                final packCount = state.packsForTrack(t.id).length;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.adminTrackForm, arguments: t),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: t.figure.isEmpty
                                ? const Icon(Icons.school_rounded,
                                    color: AppColors.yellow)
                                : Image.asset(t.figure, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('$packCount pack(s) · ${t.id}',
                                    style: TextStyle(
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _confirmDelete(context, state, t, packCount),
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.wrong),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, Track t, int packCount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete track?'),
        content: Text(
          '“${t.name}” will be removed'
          '${packCount > 0 ? ', along with its $packCount pack(s) and their questions' : ''}.',
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
      state.deleteTrack(t.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track deleted')),
        );
      }
    }
  }
}
