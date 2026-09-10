import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/assets.dart';
import '../../widgets/entrance.dart';
import '../../widgets/wave.dart';

/// "Thank you — please wait" screen. In a real build an admin confirms the
/// transfer; here we simulate a quick confirmation and move on to the success
/// screen automatically.
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
  Timer? _confirm;

  @override
  void initState() {
    super.initState();
    _confirm = Timer(const Duration(milliseconds: 3600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paySuccess,
        arguments: widget.pack,
      );
    });
  }

  @override
  void dispose() {
    _confirm?.cancel();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WaveHeader(
              height: 110,
              title: 'Thank you!',
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
                        color: AppColors.yellowDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: const Column(
                        children: [
                          Text('PLEASE',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                          Text('WAIT',
                              style: TextStyle(
                                  fontSize: 34, fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('Good things take time.',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: _clock,
                    child: const Icon(Icons.access_time_filled,
                        size: 110, color: AppColors.ink),
                  ),
                  const SizedBox(height: 30),
                  Entrance(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Your receipt was uploaded — confirming your payment now…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
