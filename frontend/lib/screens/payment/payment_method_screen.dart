import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/assets.dart';
import '../../widgets/entrance.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wave.dart';
import 'upload_receipt_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key, required this.pack});
  final ExamPack pack;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final banks = AppStateScope.of(context).banks;
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WaveHeader(
              height: 120,
              title: 'Payment Method',
              onBack: () => Navigator.of(context).maybePop(),
              avatar: const AssetImage(Img.avatar),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            sliver: SliverList.list(
              children: staggered([
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.yellowDeep,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange, width: 1.4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Transfer the exact amount to one of the bank '
                          'accounts below then proceed to upload your receipt',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Select a bank', style: AppTheme.h2),
                    const SizedBox(width: 8),
                    const Icon(Icons.account_balance, size: 24),
                  ],
                ),
                const SizedBox(height: 14),
                if (banks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No bank accounts have been set up yet — contact support.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  for (var i = 0; i < banks.length; i++)
                    _BankCard(
                      bank: banks[i],
                      selected: _selected == i,
                      onTap: () => setState(() => _selected = i),
                    ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Proceed to Receipt Upload',
                  onPressed: banks.isEmpty
                      ? null
                      : () => Navigator.of(context).pushNamed(
                            AppRoutes.payUpload,
                            arguments: UploadReceiptArgs(
                              pack: widget.pack,
                              bank: banks[_selected.clamp(0, banks.length - 1)],
                            ),
                          ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  final BankAccount bank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.yellow,
                  child: Text(bank.code[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppColors.ink)),
                ),
                const SizedBox(width: 12),
                Text(bank.code,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 2),
                    color: selected ? AppColors.ink : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: AppColors.yellow)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('Account owner', bank.owner),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _kv('Account number', bank.number)),
                PressScale(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: bank.number));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account number copied')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.yellowSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.ink),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 14),
                        SizedBox(width: 4),
                        Text('Copy',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.6))),
        Text(v,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }
}
