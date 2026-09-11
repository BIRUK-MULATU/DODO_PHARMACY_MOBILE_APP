import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Admin "Q&A" — every question a learner has asked from the app's Q&A
/// screen, oldest-unanswered-first, with an inline composer to answer (or
/// edit a previous answer) and a way to remove spam/duplicates.
class AdminQaScreen extends StatefulWidget {
  const AdminQaScreen({super.key});

  @override
  State<AdminQaScreen> createState() => _AdminQaScreenState();
}

class _AdminQaScreenState extends State<AdminQaScreen> {
  List<QaItem>? _items;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppStateScope.read(context);
    if (!state.isOnline) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await state.fetchAllQuestions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _answer(String id, String answer) async {
    final state = AppStateScope.read(context);
    final updated = await state.answerQuestion(id: id, answer: answer);
    if (!mounted) return;
    setState(() {
      final list = _items;
      if (list == null) return;
      final i = list.indexWhere((q) => q.id == id);
      if (i != -1) list[i] = updated;
    });
  }

  void _delete(String id) {
    AppStateScope.read(context).deleteQuestionThread(id);
    setState(() => _items?.removeWhere((q) => q.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    // Offline there's only ever the one demo learner, so fall back to their
    // own thread (state.qaItems) — reading it live means answering it here
    // updates the Q&A screen instantly too, same AppState instance.
    final items = state.isOnline ? _items : state.qaItems;
    final pending = items?.where((q) => q.status == QaStatus.pending).length ?? 0;

    return AdminScaffold(
      title: pending > 0 ? 'Q&A ($pending pending)' : 'Q&A',
      onBack: () => Navigator.of(context).maybePop(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Notice(
                  icon: Icons.error_outline_rounded,
                  text: "Couldn't load questions. Pull down to try again.",
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: (items == null || items.isEmpty)
                      ? ListView(
                          padding: const EdgeInsets.all(32),
                          children: const [
                            Center(child: Text('No questions yet.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _QuestionCard(
                            item: items[i],
                            onAnswer: (text) => _answer(items[i].id, text),
                            onDelete: () => _delete(items[i].id),
                          ),
                        ),
                ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.item,
    required this.onAnswer,
    required this.onDelete,
  });

  final QaItem item;
  final Future<void> Function(String answer) onAnswer;
  final VoidCallback onDelete;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late final _controller = TextEditingController(text: widget.item.answer);
  bool _editing = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onAnswer(text);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _editing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send the answer. Try again.")),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this question?'),
        content: const Text('This deletes it for good.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final answered = item.status == QaStatus.answered;
    final showComposer = !answered || _editing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.askedByName,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink.withValues(alpha: 0.5))),
                    const SizedBox(height: 2),
                    Text(item.question,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(answered: answered),
              IconButton(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (answered && !_editing) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.answer, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _editing = true),
                      child: const Text('Edit answer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showComposer) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write an answer…',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_editing)
                  TextButton(
                    onPressed: () => setState(() {
                      _editing = false;
                      _controller.text = item.answer;
                    }),
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.yellow,
                  ),
                  onPressed: _sending ? null : _submit,
                  child: Text(_sending ? 'Sending…' : 'Send answer'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.answered});
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final color = answered ? AppColors.correct : AppColors.wrong;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        answered ? 'Answered' : 'Pending',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
