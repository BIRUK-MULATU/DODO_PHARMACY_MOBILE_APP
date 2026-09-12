import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Add (when [bank] is null) or edit a bank account.
class AdminBankFormScreen extends StatefulWidget {
  const AdminBankFormScreen({super.key, this.bank});

  final BankAccount? bank;

  @override
  State<AdminBankFormScreen> createState() => _AdminBankFormScreenState();
}

class _AdminBankFormScreenState extends State<AdminBankFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _owner;
  late final TextEditingController _number;

  bool get _isEdit => widget.bank != null;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.bank?.code ?? '');
    _name = TextEditingController(text: widget.bank?.name ?? '');
    _owner = TextEditingController(text: widget.bank?.owner ?? '');
    _number = TextEditingController(text: widget.bank?.number ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _owner.dispose();
    _number.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateScope.read(context);
    if (_isEdit) {
      state.updateBank(widget.bank!.copyWith(
        name: _name.text.trim(),
        owner: _owner.text.trim(),
        number: _number.text.trim(),
      ));
    } else {
      final code = _code.text.trim().toUpperCase();
      if (state.bankByCode(code) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A bank with code "$code" already exists')),
        );
        return;
      }
      state.addBank(BankAccount(
        code: code,
        name: _name.text.trim(),
        owner: _owner.text.trim(),
        number: _number.text.trim(),
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Bank updated' : 'Bank added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _isEdit ? 'Edit bank' : 'New bank',
      onBack: () => Navigator.of(context).maybePop(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _label('Bank code'),
            TextFormField(
              controller: _code,
              enabled: !_isEdit,
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Too short' : null,
              decoration: InputDecoration(
                hintText: 'e.g. CBE, BOA, AWASH',
                filled: true,
                fillColor: _isEdit ? Colors.black12 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _label('Bank name'),
            TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Too short' : null,
              decoration: InputDecoration(
                hintText: 'e.g. Commercial Bank of Ethiopia',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _label('Account owner'),
            TextFormField(
              controller: _owner,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: InputDecoration(
                hintText: 'Full name on the account',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _label('Account number'),
            TextFormField(
              controller: _number,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: InputDecoration(
                hintText: 'e.g. 1000641510584',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.yellow,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Add bank',
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
}
