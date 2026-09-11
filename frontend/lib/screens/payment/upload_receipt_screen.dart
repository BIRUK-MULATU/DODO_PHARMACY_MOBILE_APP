import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_bits.dart';
import '../../widgets/app_image.dart';
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
  String? _receipt;
  bool _picking = false;

  Future<void> _pickReceipt() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final uri = await pickImageAsDataUri(maxWidth: 1400);
      if (!mounted) return;
      if (uri != null) setState(() => _receipt = uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Couldn't open the image picker. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final used = state.uploadAttempts;
    final remaining = UploadReceiptScreen.maxAttempts - used;
    final pack = widget.args.pack;
    final bank = widget.args.bank;
    final picked = _receipt != null;

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
                          const Flexible(
                            child: Text('Upload Attempts',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ),
                          const SizedBox(width: 8),
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
                  onTap: _picking ? null : _pickReceipt,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    clipBehavior: Clip.antiAlias,
                    height: 170,
                    decoration: BoxDecoration(
                      color: AppColors.yellowSoft.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: picked ? AppColors.correct : AppColors.ink,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _picking
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.ink))
                        : picked
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  AppImage(_receipt!, fit: BoxFit.cover),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(
                                                alpha: 0.55),
                                          ],
                                          stops: const [0.5, 1],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    right: 10,
                                    top: 10,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.correct,
                                      child: Icon(Icons.check,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 10,
                                    child: Text(
                                      'Receipt attached · tap to replace',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cloud_upload,
                                        color: Colors.blue, size: 44),
                                    SizedBox(height: 8),
                                    Text('Tap to upload receipt',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    Text('a photo or screenshot from your device',
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
                  onPressed: picked && remaining > 0
                      ? () {
                          state.registerUploadAttempt();
                          state.submitPaymentRequest(
                            pack: pack,
                            bankCode: bank.code,
                            receiptImage: _receipt!,
                          );
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
