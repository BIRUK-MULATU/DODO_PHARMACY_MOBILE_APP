import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_bits.dart';
import '../../widgets/assets.dart';
import '../../widgets/entrance.dart';
import '../../widgets/primary_button.dart';

class PaymentPromptScreen extends StatelessWidget {
  const PaymentPromptScreen({super.key, required this.pack});
  final ExamPack pack;

  @override
  Widget build(BuildContext context) {
    final name = AppStateScope.of(context).profile.name.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Entrance(
                delay: const Duration(milliseconds: 200),
                offset: const Offset(0, 60),
                child: Image.asset(Img.payHero,
                    fit: BoxFit.contain,
                    height: MediaQuery.of(context).size.height * 0.7),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.yellow, size: 32),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Entrance(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 40,
                                fontWeight: FontWeight.w900),
                            children: [
                              const TextSpan(
                                  text: 'HI! ',
                                  style: TextStyle(color: Colors.white)),
                              TextSpan(
                                  text: name.toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.yellow)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Entrance(
                        delay: const Duration(milliseconds: 120),
                        child: Container(
                          padding: const EdgeInsets.only(left: 14),
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                  color: AppColors.yellow, width: 4),
                            ),
                          ),
                          child: const Text(
                            'You need to pay\nthe rest of question',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.3,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Entrance(
                        delay: const Duration(milliseconds: 240),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 38,
                                fontWeight: FontWeight.w900),
                            children: [
                              TextSpan(
                                  text: '${pack.priceBirr} ',
                                  style: const TextStyle(
                                      color: AppColors.yellow)),
                              const TextSpan(
                                  text: 'BIRR',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                  child: Entrance(
                    delay: const Duration(milliseconds: 380),
                    child: Pulse(
                      child: PrimaryButton(
                        label: 'Pay Now',
                        style: DpButtonStyle.yellow,
                        expand: false,
                        trailingIcon: Icons.volunteer_activism,
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.payMethod,
                          arguments: pack,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
