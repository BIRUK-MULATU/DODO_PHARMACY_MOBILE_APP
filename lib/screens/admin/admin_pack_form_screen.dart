import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
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
  }

  @override
  void dispose() {
    _title.dispose();
    _count.dispose();
    _price.dispose();
    _free.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateScope.read(context);
    final count = int.tryParse(_count.text) ?? 0;
    final price = int.tryParse(_price.text) ?? 0;
    final free = int.tryParse(_free.text) ?? 0;

    if (_isEdit) {
      state.updatePack(widget.pack!.copyWith(
        trackId: _trackId,
        title: _title.text.trim(),
        image: _image,
        questionCount: count,
        priceBirr: price,
        freeLimit: free,
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
            _label('Cover image'),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final img in MockData.packImages)
                    GestureDetector(
                      onTap: () => setState(() => _image = img),
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _image == img
                                ? AppColors.ink
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(img, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
  }) {
    return TextFormField(
      controller: c,
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
