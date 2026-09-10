import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'admin_scaffold.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final approved = state.paymentRequests
        .where((r) => r.status == PaymentStatus.approved)
        .length;

    return AdminScaffold(
      title: 'Admin panel',
      actions: [
        TextButton.icon(
          onPressed: () {
            state.logOut();
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
          },
          icon: const Icon(Icons.logout, color: AppColors.yellow, size: 18),
          label: const Text('Exit',
              style: TextStyle(
                  color: AppColors.yellow, fontWeight: FontWeight.w700)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Row(
            children: [
              _Stat(label: 'Questions', value: '${state.questions.length}'),
              const SizedBox(width: 12),
              _Stat(
                  label: 'Pending pay',
                  value: '${state.pendingPaymentCount}',
                  highlight: state.pendingPaymentCount > 0),
              const SizedBox(width: 12),
              _Stat(label: 'Approved', value: '$approved'),
            ],
          ),
          const SizedBox(height: 20),
          AdminTile(
            icon: Icons.quiz_rounded,
            title: 'Questions',
            subtitle: 'Add, edit or remove exam questions',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminQuestions),
          ),
          const SizedBox(height: 12),
          AdminTile(
            icon: Icons.payments_rounded,
            title: 'Payment requests',
            subtitle: 'Approve or reject uploaded receipts',
            badge: state.pendingPaymentCount,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminPayments),
          ),
          const SizedBox(height: 12),
          AdminTile(
            icon: Icons.folder_special_rounded,
            title: 'Exam packs',
            subtitle: '${MockData.examPacks.length} packs · price & free limit',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminPacks),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.ink),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.home),
            icon: const Icon(Icons.smartphone, size: 18),
            label: const Text('Preview the app',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: highlight ? AppColors.wrong : AppColors.ink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: (highlight ? Colors.white : AppColors.yellow)
                        .withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
