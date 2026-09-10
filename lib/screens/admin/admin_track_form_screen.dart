import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Add (when [track] is null) or edit a track (field of study).
class AdminTrackFormScreen extends StatefulWidget {
  const AdminTrackFormScreen({super.key, this.track});

  final Track? track;

  @override
  State<AdminTrackFormScreen> createState() => _AdminTrackFormScreenState();
}

class _AdminTrackFormScreenState extends State<AdminTrackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _figure;

  bool get _isEdit => widget.track != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.track?.name ?? '');
    _figure = widget.track?.figure ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateScope.read(context);
    if (_isEdit) {
      state.updateTrack(widget.track!.copyWith(
        name: _name.text.trim(),
        figure: _figure,
      ));
    } else {
      state.addTrack(Track(
        id: state.newTrackId(),
        name: _name.text.trim(),
        figure: _figure,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Track updated' : 'Track added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _isEdit ? 'Edit track' : 'New track',
      onBack: () => Navigator.of(context).maybePop(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _label('Track name'),
            TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Too short' : null,
              decoration: InputDecoration(
                hintText: 'e.g. Pharmacy, Nursing, Midwifery',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _label('Card figure (optional)'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _figureOption('', label: 'None'),
                for (final f in MockData.trackFigures) _figureOption(f),
              ],
            ),
            const SizedBox(height: 26),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.yellow,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Add track',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _figureOption(String path, {String? label}) {
    final selected = _figure == path;
    return GestureDetector(
      onTap: () => setState(() => _figure = path),
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.black12,
            width: selected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: path.isEmpty
            ? Center(
                child: Text(label ?? 'None',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)))
            : Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );
}
