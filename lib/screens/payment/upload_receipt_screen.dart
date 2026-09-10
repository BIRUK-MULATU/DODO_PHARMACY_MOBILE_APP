import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_bits.dart';
import '../../widgets/assets.dart';
import '../../widgets/entrance.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wave.dart';

class UploadReceiptArgs {
  const UploadReceiptArgs({required this.pack, required this.bank});
  final ExamPack pack;
  final BankAccount bank;
}

class UploadReceiptScreen extends StatefulWidget {
  const UploadReceiptScreen({super.key, required this.args});
  final UploadReceiptArgs args;

  static const int maxAttempts = 3;

  @override
  State<UploadReceiptScreen> createState() => _UploadReceiptScreenState();
}

class _UploadReceiptScreenState extends State<UploadReceiptScreen> {
  bool _picked = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final used = state.uploadAttempts;
    final remaining = UploadReceiptScreen.maxAttempts - used;
    final pack = widget.args.pack;
    final bank = widget.args.bank;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WaveHeader(
              height: 120,
              title: 'Upload Receipt',
              onBack: () => Navigator.of(context).maybePop(),
              avatar: const AssetImage(Img.avatar),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            sliver: SliverList.list(
              children: staggered([
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.yellow,
                        child: Text(bank.code[0],
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bank.code,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                            Text(pack.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('ETB ${pack.priceBirr}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const Icon(Icons.account_balance, size: 26),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Upload Attempts',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('$used/${UploadReceiptScreen.maxAttempts}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedProgressBar(
                        value: used / UploadReceiptScreen.maxAttempts,
                        height: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Exceeding ${UploadReceiptScreen.maxAttempts} uploads '
                        'will permanently block your account',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PressScale(
                  onTap: () => setState(() => _picked = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 170,
                    decoration: BoxDecoration(
                      color: AppColors.yellowSoft.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _picked ? AppColors.correct : AppColors.ink,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: _picked
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle,
                                    color: AppColors.correct, size: 44),
                                SizedBox(height: 8),
                                Text('receipt_2027.jpg selected',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.cloud_upload,
                                    color: Colors.blue, size: 44),
                                SizedBox(height: 8),
                                Text('Tap to upload receipt',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800)),
                                Text('JPG or PNG from your gallery',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Submit Receipt',
                  style: DpButtonStyle.outline,
                  trailingIcon: Icons.send_rounded,
                  onPressed: _picked && remaining > 0
                      ? () {
                          state.registerUploadAttempt();
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.payPending,
                            arguments: pack,
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text('$remaining upload attempts remaining',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
