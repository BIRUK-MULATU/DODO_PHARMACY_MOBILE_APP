import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dp_logo.dart';
import '../widgets/entrance.dart';
import '../widgets/wave.dart';

/// "About the app" — reached from the side drawer.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Column(
        children: [
          WaveHeader(
            height: 116,
            title: 'About',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: staggered([
                  Center(
                    child: Column(
                      children: [
                        const DpLogo(size: 76, color: AppColors.ink),
                        const SizedBox(height: 10),
                        const Text('DODOMED',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('Version $_version',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'DODOMED is a study companion for the Ethiopian pharmacy '
                    'exit exam and the COC licensure exam. It brings the full '
                    'question bank, worked explanations, mock exams and premium '
                    'reference books into one app so you can prepare anywhere.',
                    style: AppTheme.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('What you get'),
                  const SizedBox(height: 10),
                  ..._features.map((f) => _Bullet(f)),
                  const SizedBox(height: 22),
                  const _SectionTitle('How unlocking works'),
                  const SizedBox(height: 10),
                  Text(
                    'A few questions and the first pages of every book are free. '
                    'To unlock everything you make a bank transfer and upload the '
                    'receipt in the app — our team confirms it (usually within a '
                    'couple of hours) and your access opens automatically.',
                    style: AppTheme.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Support'),
                  const SizedBox(height: 10),
                  const _InfoRow(
                      icon: Icons.mail_outline, text: 'support@dodomed.et'),
                  const _InfoRow(
                      icon: Icons.send_rounded, text: 'Telegram: @dodomed'),
                  const _InfoRow(
                      icon: Icons.phone_outlined, text: '+251 91 000 0000'),
                  const SizedBox(height: 26),
                  Center(
                    child: Text(
                      '© 2026 DODOMED · Made in Ethiopia',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _features = [
    '3,000+ exit-exam MCQs and 2,800+ COC questions, organised by subject and '
        'past-paper trends',
    'A step-by-step explanation for every question — why the answer is right '
        'and why the others are wrong',
    'Timed mock exams that mirror the real paper',
    'Premium reference books, including full PDFs, readable in the app',
    'A progress dashboard: accuracy, streaks and exam-readiness at a glance',
  ];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900));
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.ink),
          ),
          Expanded(child: Text(text, style: AppTheme.body.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}
