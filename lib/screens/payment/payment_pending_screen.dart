import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/assets.dart';
import '../../widgets/entrance.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wave.dart';

/// "Thank you — under review" screen. The receipt now waits for an admin to
/// approve or reject it from the admin panel; this screen reacts to that.
class PaymentPendingScreen extends StatefulWidget {
  const PaymentPendingScreen({super.key, required this.pack});

  final ExamPack pack;

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  AppState? _state;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppStateScope.of(context);
    if (s != _state) {
      _state?.removeListener(_check);
      _state = s..addListener(_check);
    }
  }

  void _check() {
    if (_navigated || !mounted) return;
    final req = _state!.paymentRequestFor(widget.pack.id);
    if (req?.status == PaymentStatus.approved) {
      _navigated = true;
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.paySuccess, arguments: widget.pack);
    } else {
      setState(() {}); // reflect a rejection
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_check);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = AppStateScope.of(context).paymentRequestFor(widget.pack.id);
    final rejected = req?.status == PaymentStatus.rejected;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WaveHeader(
              height: 110,
              title: rejected ? 'Payment rejected' : 'Thank you!',
              onBack: () => Navigator.of(context).maybePop(),
              avatar: const AssetImage(Img.avatar),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
              child: Column(
                children: [
                  Entrance(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: rejected
                            ? AppColors.wrongFill
                            : AppColors.yellowDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text(rejected ? 'SORRY' : 'PLEASE',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                          Text(rejected ? 'TRY AGAIN' : 'WAIT',
                              style: const TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(
                            rejected
                                ? 'The receipt could not be verified.'
                                : 'Good things take time.',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!rejected) ...[
                    RotationTransition(
                      turns: _clock,
                      child: const Icon(Icons.access_time_filled,
                          size: 100, color: AppColors.ink),
                    ),
                    const SizedBox(height: 26),
                  ] else
                    const Icon(Icons.receipt_long_rounded,
                        size: 96, color: AppColors.ink),
                  const SizedBox(height: 20),
                  Entrance(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        rejected
                            ? 'Please re-check the transfer and upload a valid '
                                'receipt again.'
                            : 'Your receipt was uploaded and is being reviewed '
                                'by our team. You’ll be unlocked once it is '
                                'confirmed (usually 1–2 hr).',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.yellow,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: rejected ? 'Upload again' : 'Back to Home',
                    style: DpButtonStyle.yellow,
                    onPressed: () {
                      if (rejected) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.home, (r) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
