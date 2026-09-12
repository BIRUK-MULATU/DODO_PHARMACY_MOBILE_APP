import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'package:dodomed_core/widgets/app_image.dart';
import 'admin_scaffold.dart';

void _viewReceipt(BuildContext context, String receiptImage) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: AppImage(receiptImage, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final requests = state.paymentRequests.reversed.toList();

    return AdminScaffold(
      title: 'Payment requests (${state.pendingPaymentCount})',
      onBack: () => Navigator.of(context).maybePop(),
      body: requests.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No receipts uploaded yet.\nWhen a user submits a receipt it '
                  'appears here for review.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _RequestCard(request: requests[i], state: state),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.state});

  final PaymentRequest request;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = request.status == PaymentStatus.pending;
    final ts = request.submittedAt;
    final time =
        '${ts.day}/${ts.month} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.yellow,
                child: Text(request.bankCode[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${request.packTitle} · ${request.bankCode}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              _StatusPill(status: request.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('ETB ${request.amountBirr}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(time,
                  style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.45),
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          // The receipt photo the user picked from their device.
          if (request.receiptImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () => _viewReceipt(context, request.receiptImage),
                child: AppImage(
                  request.receiptImage,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 18, color: Colors.black45),
                    SizedBox(width: 6),
                    Text('No receipt attached',
                        style: TextStyle(color: Colors.black45)),
                  ],
                ),
              ),
            ),
          if (pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.wrong,
                      side: const BorderSide(color: AppColors.wrong),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => state.decidePayment(
                        request.id, PaymentStatus.rejected),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => state.decidePayment(
                        request.id, PaymentStatus.approved),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () =>
                  state.decidePayment(request.id, PaymentStatus.pending),
              child: const Text('Reset to pending'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    late Color c;
    late String t;
    switch (status) {
      case PaymentStatus.pending:
        c = Colors.orange;
        t = 'Pending';
        break;
      case PaymentStatus.approved:
        c = AppColors.success;
        t = 'Approved';
        break;
      case PaymentStatus.rejected:
        c = AppColors.wrong;
        t = 'Rejected';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(t,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
