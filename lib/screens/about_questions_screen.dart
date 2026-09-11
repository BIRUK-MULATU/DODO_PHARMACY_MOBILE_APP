import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';
import '../widgets/entrance.dart';
import '../widgets/primary_button.dart';

class AboutQuestionsScreen extends StatelessWidget {
  const AboutQuestionsScreen({super.key, required this.pack});

  final ExamPack pack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    AppImage(
                      pack.image,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _RoundArrow(
                              icon: Icons.chevron_left,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            _RoundArrow(icon: Icons.chevron_right, onTap: () {}),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.yellowOlive,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Text(
                        pack.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.list(
                  children: staggered([
                    const Text('About Questions', style: AppTheme.h1),
                    const SizedBox(height: 14),
                    Text(
                      'Ultimate Pharmacy Exit Exam Master Question Bank '
                      '(${pack.questionCount}+ MCQs & Detailed Explanations)',
                      style: AppTheme.label.copyWith(fontSize: 17, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    for (final b in MockData.aboutBullets) _Bullet(b),
                    const SizedBox(height: 14),
                    const Text('Core Courses Covered',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    for (final c in MockData.coreCourses) _Bullet(c),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 28,
            child: Entrance(
              delay: const Duration(milliseconds: 300),
              child: PrimaryButton(
                label: 'GO to Exam',
                expand: false,
                height: 54,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.exam, arguments: pack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  const _RoundArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.yellow, size: 30),
        ),
      ),
    );
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
            padding: EdgeInsets.only(top: 7, right: 10),
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.ink),
          ),
          Expanded(child: Text(text, style: AppTheme.body)),
        ],
      ),
    );
  }
}
