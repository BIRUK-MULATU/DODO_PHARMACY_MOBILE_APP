import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_image.dart';
import 'admin_scaffold.dart';

/// Add (when [pack] is null) or edit an exam pack.
class AdminPackFormScreen extends StatefulWidget {
  const AdminPackFormScreen({super.key, this.pack});

  final ExamPack? pack;

  @override
  State<AdminPackFormScreen> createState() => _AdminPackFormScreenState();
}

class _AdminPackFormScreenState extends State<AdminPackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _count;
  late final TextEditingController _price;
  late final TextEditingController _free;
  late final TextEditingController _aboutSummary;
  late final TextEditingController _aboutBullets;
  late final TextEditingController _coreCourses;
  late String _trackId;
  late String _image;

  bool get _isEdit => widget.pack != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pack;
    final tracks = AppStateScope.read(context).tracks;
    _title = TextEditingController(text: p?.title ?? '');
    _count = TextEditingController(text: p?.questionCount.toString() ?? '');
    _price = TextEditingController(text: p?.priceBirr.toString() ?? '');
    _free = TextEditingController(text: p?.freeLimit.toString() ?? '5');
    _trackId = p?.trackId ??
        (tracks.isNotEmpty ? tracks.first.id : '');
    _image = p?.image ?? MockData.packImages.first;
    _aboutSummary = TextEditingController(text: p?.aboutSummary ?? '');
    _aboutBullets =
        TextEditingController(text: p?.aboutBullets.join('\n') ?? '');
    _coreCourses =
        TextEditingController(text: p?.coreCourses.join('\n') ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _count.dispose();
    _price.dispose();
    _free.dispose();
    _aboutSummary.dispose();
    _aboutBullets.dispose();
    _coreCourses.dispose();
    super.dispose();
  }

  List<String> _lines(String text) => text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateScope.read(context);
    final count = int.tryParse(_count.text) ?? 0;
    final price = int.tryParse(_price.text) ?? 0;
    final free = int.tryParse(_free.text) ?? 0;
    final aboutSummary = _aboutSummary.text.trim();
    final aboutBullets = _lines(_aboutBullets.text);
    final coreCourses = _lines(_coreCourses.text);

    if (_isEdit) {
      state.updatePack(widget.pack!.copyWith(
        trackId: _trackId,
        title: _title.text.trim(),
        image: _image,
        questionCount: count,
        priceBirr: price,
        freeLimit: free,
        aboutSummary: aboutSummary,
        aboutBullets: aboutBullets,
        coreCourses: coreCourses,
      ));
    } else {
      state.addPack(ExamPack(
        id: state.newPackId(),
        trackId: _trackId,
        title: _title.text.trim(),
        image: _image,
        questionCount: count,
        priceBirr: price,
        freeLimit: free,
        aboutSummary: aboutSummary,
        aboutBullets: aboutBullets,
        coreCourses: coreCourses,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Pack updated' : 'Pack added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return AdminScaffold(
      title: _isEdit ? 'Edit pack' : 'New pack',
      onBack: () => Navigator.of(context).maybePop(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _label('Pack title'),
            _field(_title,
                hint: 'e.g. 3000 Exit Question Sample Exam',
                validator: (v) =>
                    (v == null || v.trim().length < 4) ? 'Too short' : null),
            const SizedBox(height: 16),
            _label('Track'),
            if (state.tracks.isEmpty)
              const Text('No tracks yet — add one under “Tracks” first.',
                  style: TextStyle(color: AppColors.wrong)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in state.tracks)
                  ChoiceChip(
                    label: Text(t.name),
                    selected: _trackId == t.id,
                    selectedColor: AppColors.ink,
                    labelStyle: TextStyle(
                      color:
                          _trackId == t.id ? AppColors.yellow : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _trackId = t.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Question bank size'),
                      _field(_count,
                          keyboardType: TextInputType.number,
                          validator: _positiveInt),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Free questions'),
                      _field(_free,
                          keyboardType: TextInputType.number,
                          validator: _zeroOrMore),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Price (ETB)'),
            _field(_price,
                keyboardType: TextInputType.number, validator: _zeroOrMore),
            const SizedBox(height: 16),
            _label('Cover image — pick a preset or upload from your device'),
            ImagePickerRow(
              bundled: MockData.packImages,
              selected: _image,
              onSelected: (v) => setState(() => _image = v),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This pack\'s own "About Questions" screen — shown to '
                      'the learner before they start the exam.',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _label('Summary line (leave blank for a sensible default)'),
            _field(_aboutSummary,
                hint: 'e.g. Ultimate Pharmacy Exit Exam Master Question '
                    'Bank (3000+ MCQs & Detailed Explanations)',
                maxLines: 2),
            const SizedBox(height: 16),
            _label('Bullet points — one per line'),
            _field(_aboutBullets, maxLines: 6),
            const SizedBox(height: 16),
            _label('"Core Courses Covered" — one per line, leave blank to '
                'hide that section'),
            _field(_coreCourses, maxLines: 6),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.yellow,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Add pack',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String? _positiveInt(String? v) {
    final n = int.tryParse(v ?? '');
    return (n == null || n <= 0) ? 'Enter a number > 0' : null;
  }

  String? _zeroOrMore(String? v) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < 0) ? 'Enter a number' : null;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _field(
    TextEditingController c, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
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
