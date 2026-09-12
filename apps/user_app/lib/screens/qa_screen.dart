import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'package:dodomed_core/theme/app_theme.dart';
import 'package:dodomed_core/widgets/entrance.dart';
import 'package:dodomed_core/widgets/primary_button.dart';
import 'package:dodomed_core/widgets/wave.dart';

/// "Q&A" — reached from the side drawer. A learner asks a question here;
/// the admin answers it from the admin panel's own Q&A page
/// (`admin_qa_screen.dart`), and the answer shows up back here.
class QaScreen extends StatefulWidget {
  const QaScreen({super.key});

  @override
  State<QaScreen> createState() => _QaScreenState();
}

class _QaScreenState extends State<QaScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _sending = false;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = AppStateScope.read(context);
    if (!state.isOnline) return;
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      await state.fetchMyQuestions();
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    AppStateScope.read(context).askQuestion(text);
    _controller.clear();
    // A beat for the fire-and-forget sync to at least start, then let go —
    // the item is already showing locally either way.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _sending = false);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your question was sent — we\'ll answer soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.qaItems;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          WaveHeader(
            height: 116,
            title: 'Q&A',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: staggered([
                    Text(
                      'Have a question about payments, unlocking a pack, or '
                      'anything else? Ask below — our team will get back to '
                      'you here.',
                      style: AppTheme.body.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    _AskBox(
                      controller: _controller,
                      sending: _sending,
                      onSend: _send,
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        const Text('Your questions',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        if (_loading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loadError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Couldn't refresh your questions — showing what "
                          'was loaded already. Pull down to try again.',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.ink.withValues(alpha: 0.55)),
                        ),
                      ),
                    if (items.isEmpty)
                      Text(
                        "You haven't asked anything yet — your questions "
                        'will show up here once you do.',
                        style: TextStyle(
                            color: AppColors.ink.withValues(alpha: 0.55)),
                      )
                    else
                      for (final item in items) _QaCard(item: item),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AskBox extends StatelessWidget {
  const _AskBox({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Type your question…',
              border: InputBorder.none,
              counterText: '',
              isDense: true,
            ),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: sending ? 'Sending…' : 'Send',
            onPressed: sending ? null : onSend,
            trailingIcon: Icons.send_rounded,
            height: 50,
          ),
        ],
      ),
    );
  }
}

class _QaCard extends StatelessWidget {
  const _QaCard({required this.item});
  final QaItem item;

  @override
  Widget build(BuildContext context) {
    final answered = item.status == QaStatus.answered;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                child: Text(item.question,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              _StatusChip(answered: answered),
            ],
          ),
          const SizedBox(height: 6),
          Text(_formatDate(item.createdAt),
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withValues(alpha: 0.4))),
          if (answered) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.yellowOlive.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 13, color: AppColors.yellow),
                      ),
                      const SizedBox(width: 8),
                      const Text('DODOMED Support',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (item.answeredAt != null)
                        Text(_formatDate(item.answeredAt!),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink.withValues(alpha: 0.45))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.answer,
                      style: AppTheme.body.copyWith(height: 1.45)),
                ],
              ),
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
    final color = answered ? AppColors.correct : AppColors.yellowOlive;
    return Container(
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

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
