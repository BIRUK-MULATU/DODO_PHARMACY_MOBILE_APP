import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/data/pdf_store.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'package:dodomed_core/widgets/app_image.dart';
import 'admin_scaffold.dart';

/// Add (when [book] is null) or edit a premium book. The admin can either type
/// the pages or upload a PDF from their device.
class AdminBookFormScreen extends StatefulWidget {
  const AdminBookFormScreen({super.key, this.book});

  final EBook? book;

  @override
  State<AdminBookFormScreen> createState() => _AdminBookFormScreenState();
}

class _AdminBookFormScreenState extends State<AdminBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _free;
  late final TextEditingController _subjects;
  late final TextEditingController _pages;
  late String _cover;

  // PDF the admin picked / already had.
  String? _pdfPath;
  Uint8List? _pdfBytes;
  String? _pdfName;
  bool _pdfChanged = false;
  bool _saving = false;

  bool get _isEdit => widget.book != null;
  bool get _hasPdf =>
      (_pdfPath != null && _pdfPath!.isNotEmpty) ||
      (_pdfBytes != null && _pdfBytes!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _title = TextEditingController(text: b?.title ?? '');
    _price = TextEditingController(text: b?.priceBirr.toString() ?? '');
    _free = TextEditingController(text: b?.freePages.toString() ?? '4');
    _subjects = TextEditingController(text: (b?.subjects ?? const []).join(', '));
    _pages = TextEditingController(text: (b?.pages ?? const []).join('\n---\n'));
    _cover = b?.cover ?? MockData.bookCovers.first;
    _pdfPath = b?.pdfPath;
    _pdfBytes = b?.pdfBytes;
    _pdfName = b?.pdfName;
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _free.dispose();
    _subjects.dispose();
    _pages.dispose();
    super.dispose();
  }

  List<String> _parsePages() => _pages.text
      .split(RegExp(r'\n\s*---\s*\n'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  List<String> _parseSubjects() => _subjects.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _pickPdf() async {
    try {
      const group = XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
        uniformTypeIdentifiers: ['com.adobe.pdf'],
      );
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return; // user cancelled
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        _snack('That file looks empty — pick the PDF again.');
        return;
      }
      setState(() {
        _pdfName = file.name.isNotEmpty ? file.name : 'book.pdf';
        _pdfBytes = bytes;
        _pdfPath = file.path;
        _pdfChanged = true;
      });
      _snack('“${_pdfName!}” attached');
    } catch (e) {
      if (mounted) _snack("Couldn't open the file picker ($e)");
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _removePdf() {
    setState(() {
      _pdfName = null;
      _pdfBytes = null;
      _pdfPath = null;
      _pdfChanged = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final pages = _parsePages();
    if (!_hasPdf && pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Upload a PDF or type at least one page')),
      );
      return;
    }

    setState(() => _saving = true);
    final state = AppStateScope.read(context);
    final id = _isEdit ? widget.book!.id : state.newBookId();
    final price = int.tryParse(_price.text) ?? 0;

    // Persist a freshly-picked PDF to app storage (native). On web savePickedPdf
    // returns null and we keep the bytes on the model.
    var pdfPath = _pdfPath;
    var pdfBytes = _pdfBytes;
    if (_pdfChanged && _pdfBytes != null) {
      final saved = await savePickedPdf(id, _pdfBytes!);
      if (saved != null) {
        pdfPath = saved;
        pdfBytes = null;
      } else {
        pdfPath = null; // web: bytes only
      }
    } else if (_pdfChanged && _pdfBytes == null) {
      // PDF was removed.
      await deleteSavedPdf(widget.book?.pdfPath);
      pdfPath = null;
      pdfBytes = null;
    }

    final maxPages = _hasPdf ? 100000 : pages.length;
    final free = (int.tryParse(_free.text) ?? 0).clamp(0, maxPages);

    if (!mounted) return;
    if (_isEdit) {
      state.updateBook(EBook(
        id: id,
        title: _title.text.trim(),
        priceBirr: price,
        cover: _cover,
        subjects: _parseSubjects(),
        pages: pages,
        freePages: free,
        pdfPath: pdfPath,
        pdfBytes: pdfBytes,
        pdfName: _pdfName,
      ));
    } else {
      state.addBook(EBook(
        id: id,
        title: _title.text.trim(),
        priceBirr: price,
        cover: _cover,
        subjects: _parseSubjects(),
        pages: pages,
        freePages: free,
        pdfPath: pdfPath,
        pdfBytes: pdfBytes,
        pdfName: _pdfName,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Book updated' : 'Book added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _isEdit ? 'Edit book' : 'New book',
      onBack: () => Navigator.of(context).maybePop(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _label('Book title'),
            _field(_title,
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Too short' : null),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Price (ETB)'),
                      _field(_price,
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') == null ||
                                  int.parse(v!) < 0)
                              ? 'Number'
                              : null),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Free preview pages'),
                      _field(_free,
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') == null ||
                                  int.parse(v!) < 0)
                              ? 'Number'
                              : null),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Subjects (comma separated)'),
            _field(_subjects, hint: 'Pharmacology, Clinical Pharmacy, …'),
            const SizedBox(height: 16),
            _label('Cover image — pick a preset or upload from your device'),
            ImagePickerRow(
              bundled: MockData.bookCovers,
              selected: _cover,
              onSelected: (v) => setState(() => _cover = v),
              tileWidth: 64,
              tileHeight: 84,
            ),
            const SizedBox(height: 20),
            _label('Book file (PDF)'),
            _PdfPicker(
              name: _pdfName,
              hasPdf: _hasPdf,
              onPick: _pickPdf,
              onRemove: _removePdf,
            ),
            const SizedBox(height: 16),
            _label(_hasPdf
                ? 'Pages (optional — the PDF is used instead)'
                : 'Pages — separate each page with a line containing only ---'),
            _field(
              _pages,
              hint: 'Page one text…\n---\nPage two text…',
              maxLines: 10,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.yellow,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.yellow),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Add book',
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

class _PdfPicker extends StatelessWidget {
  const _PdfPicker({
    required this.name,
    required this.hasPdf,
    required this.onPick,
    required this.onRemove,
  });

  final String? name;
  final bool hasPdf;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (hasPdf) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.wrong, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name ?? 'book.pdf',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onPick, child: const Text('Replace')),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: AppColors.wrong),
            ),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink),
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: onPick,
      icon: const Icon(Icons.upload_file_rounded, size: 20),
      label: const Text('Upload PDF from device',
          style: TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
