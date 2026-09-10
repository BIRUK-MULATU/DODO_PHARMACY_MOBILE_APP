import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Add (when [question] is null) or edit an exam question.
class AdminQuestionFormScreen extends StatefulWidget {
  const AdminQuestionFormScreen({super.key, this.question});

  final Question? question;

  @override
  State<AdminQuestionFormScreen> createState() =>
      _AdminQuestionFormScreenState();
}

class _AdminQuestionFormScreenState extends State<AdminQuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prompt;
  late final TextEditingController _explanation;
  late final TextEditingController _number;
  late final List<TextEditingController> _options;
  late String _packId;
  late int _correct;

  bool get _isEdit => widget.question != null;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    final packs = AppStateScope.read(context).examPacks;
    _prompt = TextEditingController(text: q?.prompt ?? '');
    _explanation = TextEditingController(text: q?.explanation ?? '');
    _number = TextEditingController(text: q?.number.toString() ?? '');
    _options = List.generate(
      4,
      (i) => TextEditingController(
          text: (q != null && i < q.options.length) ? q.options[i] : ''),
    );
    _packId = q?.packId ?? (packs.isNotEmpty ? packs.first.id : '');
    _correct = q?.correctIndex ?? 0;
  }

  @override
  void dispose() {
    _prompt.dispose();
    _explanation.dispose();
    _number.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateScope.read(context);
    final pack = state.packById(_packId);
    if (pack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an exam pack first')),
      );
      return;
    }
    final opts = _options.map((c) => c.text.trim()).toList();

    if (_isEdit) {
      state.updateQuestion(
        widget.question!.copyWith(
          packId: _packId,
          number: int.tryParse(_number.text) ?? widget.question!.number,
          total: pack.questionCount,
          prompt: _prompt.text.trim(),
          options: opts,
          correctIndex: _correct,
          explanation: _explanation.text.trim(),
        ),
      );
    } else {
      state.addQuestion(
        Question(
          id: state.newQuestionId(),
          packId: _packId,
          number: int.tryParse(_number.text) ??
              (state.questionsForPack(_packId).length + 1),
          total: pack.questionCount,
          prompt: _prompt.text.trim(),
          options: opts,
          correctIndex: _correct,
          explanation: _explanation.text.trim(),
        ),
      );
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Question updated' : 'Question added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return AdminScaffold(
      title: _isEdit ? 'Edit question' : 'New question',
      onBack: () => Navigator.of(context).maybePop(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _label('Exam pack'),
            if (state.examPacks.isEmpty)
              const Text(
                'No packs yet — add one under “Exam packs” first.',
                style: TextStyle(color: AppColors.wrong),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in state.examPacks)
                  ChoiceChip(
                    label: Text('${p.title} · ${p.id}'),
                    selected: _packId == p.id,
                    selectedColor: AppColors.ink,
                    labelStyle: TextStyle(
                      color: _packId == p.id
                          ? AppColors.yellow
                          : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _packId = p.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Question number'),
            _field(_number,
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') == null)
                    ? 'Enter a number'
                    : null),
            const SizedBox(height: 16),
            _label('Question prompt'),
            _field(_prompt,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().length < 8) ? 'Too short' : null),
            const SizedBox(height: 16),
            _label('Options — tap the circle to mark the correct answer'),
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _correct = i),
                      icon: Icon(
                        _correct == i
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _correct == i
                            ? AppColors.success
                            : Colors.black38,
                      ),
                    ),
                    Expanded(
                      child: _field(
                        _options[i],
                        hint: 'Option ${String.fromCharCode(65 + i)}',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _label('Explanation'),
            _field(_explanation,
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.trim().length < 10) ? 'Too short' : null),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.yellow,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Add question',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _field(
    TextEditingController c, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
