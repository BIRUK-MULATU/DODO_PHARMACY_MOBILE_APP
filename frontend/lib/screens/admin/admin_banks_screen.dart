import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Full CRUD over the bank accounts shown on the payment-method screen —
/// where users are told to transfer money. Previously hardcoded with no
/// admin control at all.
class AdminBanksScreen extends StatelessWidget {
  const AdminBanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final banks = state.banks;

    return AdminScaffold(
      title: 'Bank accounts (${banks.length})',
      onBack: () => Navigator.of(context).maybePop(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.yellow,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminBankForm),
        icon: const Icon(Icons.add),
        label: const Text('New bank',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: banks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No bank accounts yet.\nUsers can’t pay until you add at '
                  'least one — tap “New bank”.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: banks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = banks[i];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.adminBankForm, arguments: b),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              b.code.isEmpty ? '?' : b.code[0],
                              style: const TextStyle(
                                  color: AppColors.yellow,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b.code} · ${b.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('${b.owner} · ${b.number}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmDelete(context, state, b),
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
      BuildContext context, AppState state, BankAccount b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete bank account?'),
        content: Text('“${b.code} · ${b.name}” will be removed. Users will '
            'no longer be able to pick it to pay.'),
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
      state.deleteBank(b.code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account deleted')),
        );
      }
    }
  }
}
