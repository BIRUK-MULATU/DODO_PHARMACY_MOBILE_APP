import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  String _query = '';
  String _packFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    var list = state.questions.where((q) {
      final matchPack = _packFilter == 'all' || q.packId == _packFilter;
      final matchText = _query.isEmpty ||
          q.prompt.toLowerCase().contains(_query.toLowerCase());
      return matchPack && matchText;
    }).toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    String packName(String id) =>
        state.packById(id)?.title ?? '(no pack)';

    return AdminScaffold(
      title: 'Questions (${state.questions.length})',
      onBack: () => Navigator.of(context).maybePop(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.yellow,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminQuestionForm),
        icon: const Icon(Icons.add),
        label: const Text('New question',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search question text…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _Chip(
                  label: 'All',
                  selected: _packFilter == 'all',
                  onTap: () => setState(() => _packFilter = 'all'),
                ),
                for (final p in state.examPacks)
                  _Chip(
                    label: p.id,
                    selected: _packFilter == p.id,
                    onTap: () => setState(() => _packFilter = p.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No questions match.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final q = list[i];
                      return _QuestionCard(
                        q: q,
                        packName: packName(q.packId),
                        onEdit: () => Navigator.of(context).pushNamed(
                          AppRoutes.adminQuestionForm,
                          arguments: q,
                        ),
                        onDelete: () => _confirmDelete(context, state, q),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, Question q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete question?'),
        content: Text('“${q.prompt.length > 80 ? '${q.prompt.substring(0, 80)}…' : q.prompt}”'),
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
      state.deleteQuestion(q.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted')),
        );
      }
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.ink,
        labelStyle: TextStyle(
          color: selected ? AppColors.yellow : Colors.black87,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.q,
    required this.packName,
    required this.onEdit,
    required this.onDelete,
  });

  final Question q;
  final String packName;
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
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _tag('#${q.number}'),
                        const SizedBox(width: 6),
                        _tag(q.packId, subtle: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.prompt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text('Answer: ${q.answerLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.wrong),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, {bool subtle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: subtle ? Colors.black.withValues(alpha: 0.06) : AppColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              color: subtle ? Colors.black54 : AppColors.yellow,
              fontSize: 11,
              fontWeight: FontWeight.w800)),
    );
  }
}
